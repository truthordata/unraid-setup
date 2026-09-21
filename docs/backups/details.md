# Restic Backups Procedure

Critical backups are conducted using `Restic` via the `user scripts` Plugin.

Using the `Restic` configuration defined by the user, `Restic` backs up the defined folders. 

Some apps/services will have their respective `/appdata` folder backed up (beyond exclusions), others additionally a media folder 
(like `Immich`'s photos), and some also their database (also `Immich`), which require a "dump" to properly backup.

If something is not an app/service, it will be backed up however needed.


## How Does Restic do backups?

Restic does a lot of magic under the hood in order to make backups efficient.

The main concept to understand is "snapshots".

### What are snapshots?

It sounds silly, but it is exactly what it sounds like: restic stores data itself as a separate layer from 
the actual file layouts themselves. This means that it can store as many "snapshots" of your drives as you want without
duplicating the data itself: it knows what data belongs to that snapshot.

### How many snapshots do we have?

We do nightly snapshots.

Long term, we store the last 7 daily, last 4 weekly (ex calendar date 1, 8, 15, 22), and last 6 monthly (Jan, Feb...), 
for a total of 17 minimum snapshots. So, if shit really hits the fan, there are numerous restore points to try.

### Each App is Stored Independently

I have separated the backups to be per app or per folder, if it's just a "data" folder.

With `resticprofile` (which is what we use to do our `restic` stuff) this is known as a "profile"...hence "`resticprofile`"!

So for example, `immich` is its own "profile": it can be accessed separately, and its snapshots are independent of
others.

for more info as to how this is defined, you can check out the sections about resticprofile below.


## Running Restic via User Scripts

To conduct the nightly Restic backup procedure, we use `User Scripts`. 

`User Scripts` automatically calls a script called `create_backups` at our designated CRON time, where it:

1. navigates to `/mnt/user/config/scripts` and calls `create_backups.sh`
2. `create_backups.sh` navigates up to `../resticprofile` and calls `do_backups.sh` to do all backups
3. `do_backups.sh` works through specified app folders (`/mnt/user/config/<app_name>`) to perform their respective backup procedures.



## Configuring Restic

Restic needs to be configured in order to conduct its backup procedures, primarily by defining input/output folder 
locations, retention policies, etc.

### The Restic Config Directory

You use and configure restic through its containing directory, `/mnt/user/config/resticprofile`.

Why is it called `resticprofile`?

`Restic` is actually run through a helper app called `ResticProfile`, which in short just a convenience wrapper around 
`Restic` to make it easier to configure. As such, the folder is named `resticprofile`. 

in short, the `/mnt/user/config/resticprofile` folder contains:
- `resticprofile` docker-compose file (how `restic` is actually executed)
- helper backup scripts
- `/cfg` folder (defines folders to backup)

### Specifying backup folders - `/cfg/profiles.yaml`

The `/cfg/profiles.yaml` file contains all the folder definitions for backups.



## The `/mnt/user/config/*` paths

If there are any custom scripts written to help with backing up various apps, they will live in their
corresponding `/mnt/user/config/<app_name>` folder.

usually this is just to handle bringing the app and/or databases up/down to back them up.


### Advanced details

#### Why Use this Folder/Script Structure

In general, most of the backup `.sh` files exist in the root `<app_name>` dir due referencing the shared compose file to
shut down the respective services and use the databases to do the backup (which is the same compose file used by the 
`Compose Manager Plus` Plugin).

#### Docker Compose

As a reminder, these paths store the actual `docker-compose` files used to maintain the apps themselves, and some have
some custom additions added by me to make management easier. Their variables are stored in the adjoining `.env` file,
and they commonly mount their respective `/container_scripts` folder inside them as `/scripts`.


## The Restic `/cfg` folder



## 