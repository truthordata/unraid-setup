#!/usr/bin/env python3

from __future__ import annotations

import fcntl
import logging
import os
import shutil
import subprocess
import sys
import time
import grp
import pwd
from dataclasses import dataclass
from pathlib import Path


# ============================================================================
# Configuration
# ============================================================================

UPLOAD_ROOT = Path("/mnt/user/user_uploads")
MOVIE_UPLOADS = UPLOAD_ROOT / "movies"
SHOW_UPLOADS = UPLOAD_ROOT / "shows"

MEDIA_ROOT = Path("/mnt/user/Media")
MOVIE_ROOT = MEDIA_ROOT / "movies"
SHOW_ROOT = MEDIA_ROOT / "shows"

LOCK_FILE = Path("/tmp/media-mover.lock")
LOG_FILE = Path("/var/log/media-mover.log")

# An upload must have been idle for at least this long before processing.
IDLE_SECONDS = 180

OWNER = pwd.getpwnam("nobody").pw_uid
GROUP = grp.getgrnam("users").gr_gid


# ============================================================================
# Logging
# ============================================================================

def configure_logging() -> logging.Logger:
    logger = logging.getLogger("media-mover")
    logger.setLevel(logging.INFO)

    formatter = logging.Formatter(
        "%(asctime)s %(levelname)-7s %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    console = logging.StreamHandler()
    console.setFormatter(formatter)
    logger.addHandler(console)

    try:
        file_handler = logging.FileHandler(LOG_FILE)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    except OSError:
        # Logging to stdout is still better than failing the entire run
        # because the log file cannot be opened.
        logger.warning("Could not open log file: %s", LOG_FILE)

    return logger


logger = configure_logging()


# ============================================================================
# Locking
# ============================================================================

class ProcessLock:
    """
    Prevents multiple copies of the mover from running simultaneously.

    The kernel releases the lock automatically if the process exits,
    including an abnormal termination.
    """

    def __init__(self, path: Path):
        self.path = path
        self._file = None

    def acquire(self) -> bool:
        self._file = self.path.open("w")

        try:
            fcntl.flock(
                self._file.fileno(),
                fcntl.LOCK_EX | fcntl.LOCK_NB,
            )
        except BlockingIOError:
            return False

        return True

    def release(self) -> None:
        if self._file is not None:
            fcntl.flock(self._file.fileno(), fcntl.LOCK_UN)
            self._file.close()
            self._file = None

    def __enter__(self) -> bool:
        return self.acquire()

    def __exit__(self, exc_type, exc_value, traceback):
        self.release()


# ============================================================================
# Upload discovery
# ============================================================================

def discover_uploads(directory: Path) -> list[Path]:
    """
    Return direct children of an upload directory.

    We deliberately do not recursively return files here. The direct child
    represents the upload unit that we will consider as a whole.
    """

    if not directory.exists():
        logger.warning("Upload directory does not exist: %s", directory)
        return []

    if not directory.is_dir():
        logger.error("Upload path is not a directory: %s", directory)
        return []

    try:
        return sorted(directory.iterdir(), key=lambda path: path.name.lower())
    except OSError:
        logger.exception("Could not scan upload directory: %s", directory)
        return []


# ============================================================================
# Activity detection
# ============================================================================

def get_tree_paths(root: Path) -> list[Path]:
    """
    Return root and everything beneath it.

    The upload root itself is excluded by callers where appropriate.
    """

    if root.is_file():
        return [root]

    paths = [root]

    try:
        for path in root.rglob("*"):
            paths.append(path)
    except OSError:
        logger.exception("Could not inspect upload tree: %s", root)

    return paths


def newest_mtime(root: Path) -> float:
    """
    Return the newest modification time anywhere in the upload tree.
    """

    newest = root.stat().st_mtime

    for path in get_tree_paths(root):
        try:
            newest = max(newest, path.stat().st_mtime)
        except OSError:
            logger.warning("Could not stat %s", path)

    return newest


def has_recent_activity(root: Path, idle_seconds: int = IDLE_SECONDS) -> bool:
    """
    Determine whether anything in the upload unit was modified recently.
    """

    cutoff = time.time() - idle_seconds

    try:
        newest = newest_mtime(root)
    except OSError:
        logger.warning("Could not determine modification time: %s", root)
        return True

    return newest > cutoff


def get_open_paths(root: Path) -> list[Path]:
    """
    Use lsof to determine whether any file beneath the upload unit is open.

    lsof is intentionally kept as an external command because it gives us
    exactly the OS-level open-file information we need.
    """

    try:
        result = subprocess.run(
            [
                "lsof",
                "-n",
                "+D",
                str(root),
            ],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        logger.exception("Could not check open files under %s", root)
        return [root]

    # lsof returns 1 when there are simply no matching open files.
    if result.returncode not in (0, 1):
        logger.error(
            "lsof failed for %s (exit code %s): %s",
            root,
            result.returncode,
            result.stderr.strip(),
        )
        return [root]

    lines = result.stdout.splitlines()

    # First line is the header.
    if len(lines) <= 1:
        return []

    open_paths: list[Path] = []

    for line in lines[1:]:
        fields = line.split()

        if not fields:
            continue

        # lsof's NAME column is normally the final field.
        name = fields[-1]

        try:
            open_paths.append(Path(name))
        except ValueError:
            pass

    return open_paths


def upload_is_ready(root: Path) -> bool:
    """
    An upload is ready only if:

      1. Nothing in it has changed during the idle period.
      2. Nothing in it is currently open.

    If either condition fails, leave the upload untouched.
    """

    if has_recent_activity(root):
        logger.info(
            "Skipping %s: activity detected within the last %s seconds",
            root,
            IDLE_SECONDS,
        )
        return False

    open_paths = get_open_paths(root)

    if open_paths:
        logger.info(
            "Skipping %s: %s open file(s) detected",
            root,
            len(open_paths),
        )

        for path in open_paths:
            logger.info("  Open: %s", path)

        return False

    return True


# ============================================================================
# Normalization interface
# ============================================================================

@dataclass
class NormalizedEntity:
    """
    Result produced by the normalization layer.

    This is deliberately the boundary between normalization and the rest
    of the application.
    """

    kind: str
    source: Path
    destination: Path


def normalize_entity(source: Path, kind: str) -> NormalizedEntity:
    """
    PLACEHOLDER.

    Eventually this function will call the real normalization engine.

    The rest of the program should not need to know how names are recognized,
    how metadata is obtained, or how canonical names are generated.
    """

    if kind == "movie":
        destination = MOVIE_ROOT / source.stem

    elif kind == "show":
        destination = SHOW_ROOT / source.name

    else:
        raise ValueError(f"Unknown entity type: {kind}")

    return NormalizedEntity(
        kind=kind,
        source=source,
        destination=destination,
    )


# ============================================================================
# Permissions
# ============================================================================

def set_directory_permissions(path: Path) -> None:
    """
    Set owner/group and enable setgid on a directory.

    setgid causes newly-created children to inherit the directory's group.
    """

    os.chown(path, OWNER, GROUP)

    current_mode = path.stat().st_mode
    new_mode = current_mode | 0o2000

    os.chmod(path, new_mode)


def set_file_ownership(path: Path) -> None:
    os.chown(path, OWNER, GROUP)


def fix_processed_tree(root: Path) -> None:
    """
    Apply nobody:users to processed content.

    Directories additionally receive the setgid bit.

    We only do this to content involved in the current operation.
    """

    if not root.exists():
        return

    paths = sorted(
        get_tree_paths(root),
        key=lambda path: len(path.parts),
    )

    for path in paths:
        try:
            if path.is_dir():
                set_directory_permissions(path)
            else:
                set_file_ownership(path)
        except OSError:
            logger.exception("Could not fix ownership/permissions: %s", path)
            raise


# ============================================================================
# Filesystem operations
# ============================================================================

def move_file(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)

    logger.info("Moving:")
    logger.info("  %s", source)
    logger.info("  → %s", destination)

    shutil.move(str(source), str(destination))


def move_directory(source: Path, destination: Path) -> None:
    """
    Move an entire directory when the destination does not already exist.
    """

    destination.parent.mkdir(parents=True, exist_ok=True)

    logger.info("Moving directory:")
    logger.info("  %s", source)
    logger.info("  → %s", destination)

    shutil.move(str(source), str(destination))


def merge_directory(source: Path, destination: Path) -> None:
    """
    Merge the contents of source into destination.

    This is primarily intended for shows, where separate uploads may
    represent different seasons/episodes of the same show.

    Existing destination files are never overwritten.
    """

    destination.mkdir(parents=True, exist_ok=True)

    for source_child in source.iterdir():
        destination_child = destination / source_child.name

        if destination_child.exists():
            logger.error(
                "Destination already exists; leaving source untouched: %s",
                destination_child,
            )
            continue

        logger.info(
            "Moving %s → %s",
            source_child,
            destination_child,
        )

        shutil.move(str(source_child), str(destination_child))

    # Only remove the source once everything that could be moved has been
    # successfully moved.
    try:
        source.rmdir()
    except OSError:
        logger.error(
            "Source directory is not empty after processing: %s",
            source,
        )
        raise


# ============================================================================
# Entity processing
# ============================================================================

def process_movie(source: Path) -> None:
    logger.info("Processing movie upload: %s", source)

    normalized = normalize_entity(source, "movie")

    logger.info("Normalized destination: %s", normalized.destination)

    if source.is_file():
        destination = normalized.destination / source.name
        move_file(source, destination)

    elif source.is_dir():
        if normalized.destination.exists():
            logger.error(
                "Movie destination already exists: %s",
                normalized.destination,
            )
            return

        move_directory(source, normalized.destination)

    else:
        logger.error("Unsupported movie upload: %s", source)
        return

    fix_processed_tree(normalized.destination)

    if source.exists():
        raise RuntimeError(
            f"Movie source still exists after processing: {source}"
        )

    logger.info("Movie processed successfully: %s", source)


def process_show(source: Path) -> None:
    logger.info("Processing show upload: %s", source)

    if not source.is_dir():
        logger.error(
            "Show upload must be a directory; leaving untouched: %s",
            source,
        )
        return

    normalized = normalize_entity(source, "show")

    logger.info("Normalized destination: %s", normalized.destination)

    if normalized.destination.exists():
        logger.info(
            "Show already exists; merging upload into existing show: %s",
            normalized.destination,
        )

        merge_directory(
            source,
            normalized.destination,
        )
    else:
        move_directory(
            source,
            normalized.destination,
        )

    fix_processed_tree(normalized.destination)

    if source.exists():
        raise RuntimeError(
            f"Show source still exists after processing: {source}"
        )

    logger.info("Show processed successfully: %s", source)


def process_upload(source: Path, kind: str) -> None:
    logger.info("------------------------------------------------------------")
    logger.info("Considering %s upload: %s", kind, source)

    if not upload_is_ready(source):
        return

    try:
        if kind == "movie":
            process_movie(source)

        elif kind == "show":
            process_show(source)

        else:
            raise ValueError(f"Unknown upload type: {kind}")

    except Exception:
        logger.exception(
            "Failed to process %s upload: %s",
            kind,
            source,
        )


# ============================================================================
# Main
# ============================================================================

def main() -> int:
    logger.info("Starting media mover")

    lock = ProcessLock(LOCK_FILE)

    if not lock.acquire():
        logger.info("Another media mover instance is already running; exiting")
        return 0

    try:
        movie_uploads = discover_uploads(MOVIE_UPLOADS)
        show_uploads = discover_uploads(SHOW_UPLOADS)

        logger.info(
            "Found %d movie upload(s) and %d show upload(s)",
            len(movie_uploads),
            len(show_uploads),
        )

        for upload in movie_uploads:
            process_upload(upload, "movie")

        for upload in show_uploads:
            process_upload(upload, "show")

        logger.info("Media mover finished")

    except Exception:
        logger.exception("Catastrophic error in media mover")
        return 1

    finally:
        lock.release()

    return 0


if __name__ == "__main__":
    sys.exit(main())