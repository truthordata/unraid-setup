# Unraid Setup

Before running any scripts here or exploring, you should make sure you fully 
run through the manual setup steps outlined here.


# Install Unraid

Install Unraid by looking up the OS and following the setup guide using your USB drive.

## Set Up Admin Account
Once your USB is plugged in and you boot off it, it's time to set up your admin account!

This is what you will use to log in anytime you want to mess with the Unraid OS.

## Set Up Your Storage

There are 3 main classes of storage:

- `Primary`
  - Set to NVME drive
  - Used for application config and runtimes
- `Cache`
  - Set to SSD
  - Used as a "staging/waiting ground" for the `Array`
- `Array`
  - Set to (all of) your HDDs
  - Used for long term user storage, particularly for larger files
  - This is where most of your traditional "files" will go


## Start your array

You cant really do anything else until you "run" your array, so you'll start your 
array once your storage is set up.

Later on, you'll set this to auto-start when the OS starts.

To expand your storage later on, you'll spin your array down, disable auto-start,
install your new drives, and then repeat this section!


# Adding Shares

Now that you are fully up and running with Unraid (technically), we can start doing stuff.

The first thing that should be done is adding shares, which are basically just
data folders which are unique to Unraid.

They are the core feature of Unraid: Unraid is first and foremost a NAS 
(Network Attached Storage). It is meant to be seen as a drive to your other
computers on your local network. 

Shares are your network drive folders, but with some extra features/functionality.

In short, shares:
- are independent network-accessible folders
- Obfuscate/simplify your unraid disk drive management layer for those folders.
- Allows setting of access permissions for each share for users.
  - (Users can be managed via the `user` tab)


## Setting up a share

When setting up a share, you'll have to set a few options.

- Primary Storage: Which drive should these folders live on?
- Secondary Storage: Where to migrate data to once Primary is full, or migration conditions are met

Typically, this will generally be set as either:

#### SHARE TYPE-1
- `Primary Storage` --> Primary 
- `Secondary Storage` --> None

OR

#### SHARE TYPE-2
- `Primary Storage` --> Cache
- `Secondary Storage` --> Array


As a general rule of thumb: unraid operational folders use type-1, user
data and media files use type-2.

It'll make more sense later, keep reading!

### REMINDER: shares are JUST FOLDERS.

Shares in the end are _just folders_! You can add folders inside it, files, etc just like 
any other folder. 

The "share" aspect just sets access permissions and storage configuration
for that folder (and everything in it).


## Required shares

These are folders that are assumed to exist when you basically install any application.

They mostly aren't set up to begin with since users fully manage the drives.

So, in the UI, set up the following shares and storage types based on the
earlier type reference:

- appdata: `type-1`
- system: `type-1`

## Recommended shares

These are folders that I've personally set up and the only dependencies are self-made.

Many of these are ones you'd commonly want anyway, but you are welcome to add/rename/exclude
as desired...just note that some of the underlying scripts I've made often expect these exact names.

- `Photos`: `type-2`
- `Videos`: `type-2`
- `Documents`: `type-2`
- `Repos`: `type-1`
- `config`: `type-1`
- `secrets`: `type-1`
- `backups`: `type-2`

#### Side note: naming convention

I personally tried to give `Capitalized` names for more user-centric media folders
(like `Photos`), and more operational folders with fully `lower-cased` names (like `appconfig`).

In general, `lower-cased` names will be `type-1` since they are generally small, and will 
be explicitly backed up (more on that later).

`Capitalized` will generally be user content, always growing, and want "soft-backups", 
will almost always be `type-2`.

This is entirely personal preference, but if you use my scripts you might be stuck with it unless
you feel like being adventurous =)