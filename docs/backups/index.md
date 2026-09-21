# Backups Overview

Almost everything on Unraid is backed up in some capacity, but the degree of which depends on the content.

## What is "Fully" Backed Up

Because we store a lot on the server, only certain things will be backed up since backups still 
require a significant portion of the original space. 

#### Personal Effects

- documents
- photos

#### Application configurations

These are generally small enough that they are worth keeping, as if something were to fail on the server,
it would make it relatively painless to get it back up and running.

- `/mnt/user/appdata`
- corresponding databases
- docker compose files
- app templates

## What is NOT "Fully" Backed Up

Basically, our large video and music library is not backed up beyond the parity drive.

There might be some other random things, but that should be it.


## HDD Array-based Backup (Parity Drive)

Most things on the server live long-term on the Unraid Array (the large HDD's). These are backed up through a "parity drive",
which means should 1 drive fail, the parity drive should be able to replicate that drive's contents to a fresh drive.

This is the first line of defense for most of our content.


## Restic-based Backup

`Restic` is basically a special backup tool which can easily track changes as files are added/removed, making it
lightweight once the initial backup is made.

You have to manually define locations to back up, and it tracks changes to those directories as content is added
whenever you tell it to run a backup procedure. You can also synchronize those changes to any number of remote destinations.
Everything is encrypted.

#### Non-HDD content
Some of our content is not stored on the HDD's, of which we'll manually back up using `restic` to assist in restoration,
should we need it.

#### HDD content
As an additional precaution, we will also back up any personal files that are irreplaceable, like photos, even
though they are also stored on the HDD array.

#### Local Backup

The `Restic` backup will have a local version of it stored on the HDD array at `/mnt/user/backups`.

You cannot realistically browse it like a normal folder. It is meant to be interacted with via `Restic`.

#### Remote Backup

The `Restic` backup will also have a version of it stored remotely on an external storage service.
