# What is `ResticProfile`?

ResticProfile is a wrapper/helper tool for Restic, which is a
file backup tool (it includes Restic).

It works by chunking files up (which is designated by the user) and storing them
in what is called a "restic repository", which is just a designated folder on a computer.

Each repository has a unique location: typically you'll set up at least 2 repositories: 
at least 1 remote backup and at least 1 local backup.

## Why use Restic?

First: you need to have backups when you host your own content, especially
a remote copy, in case of catastrophic failure of your server.

But why use restic?

- Everything produced by restic is encrypted and obfuscated;
no one can see what it stored except you, so you can safely store it anywhere.
- Restic backups are iterative: once you do the first one, it knows what it backed up
previously, and just adds on the previous one.
- Each backup generated is called a "snapshot", and multiple snapshots can be 
stored (due to previous point) with almost no extra data.

## What should you back up?

- Photos / Family movies
- Documents
- certain application metadata or databases (that are not just temp, easily-remade files)

You could opt to back up things like movies, but I prefer not to; I keep backups for things I
absolutely cannot afford to have lost or would be time-consuming to restore/replace (yeah, 
movies could fit this category sometimes, but it's not worth the disk space to me).

I also will back up application data since often it does not take up much space and would be
annoying to restore (ex: immich, which keeps its album structures via a database).

Don't forget that you do have _some_ redundancy with your HDD array; this is just for
critical things. While restic CAN compress some things, it still will require some large % of the 
original data size.
