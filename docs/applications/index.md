# Applications and Utilities

This section gives you a rundown of various applications installed on the Unraid server.

## What do we call an "Application"?

Unfortunately, Unraid blurs the lines of how applications are installed compared to
most operating systems.

Because Unraid is not really an installed OS and (it instead runs off of a USB drive, attempting to keep as few 
additional files as possible), you don't really "install" most "applications" in the traditional sense. The way Unraid adds
functionality varies, which will be explained below.

With that said, lets explain both how things are "installed", and how you find your installed things.

## The Unraid UI `Apps` Tab

Most installed things will be represented under the "Apps" tab of the Unraid UI. 

The "Apps" tab is like an app store of sorts.

However, these only represent the configuration or presence of said thing and not the running application itself (if not installed,
it will give you the option to).


### Unraid Templates

Most "apps" here simply represent an "Unraid Template"; these templates are just friendly interfaces for configuring a 
docker image.

Normally docker images have to be configured on the command line - but Unraid tried to simply the procedure with these templates.

Docker itself has a similar templating option called Docker Compose, which is used a lot instead of managing image deployments manually.

You'll see Docker Compose used a lot with Unraid too - see the [Docker wiki section](../docker) for more info.


### Okay, so where are the apps found?

Installed apps will be represented/accessible in one of 3 locations, all of which are Unraid UI navigation tabs:

- `Docker` (usually)
- `Plugins` (sometimes)
- `Settings` (generally overlaps with plugins)

See the following sections for a deeper dive.

## The Unraid UI `Docker` Tab

Most applications are long-running pieces of software (often called "services") when it comes to Unraid. Some examples:

- Jellyfin
- Navidrome
- Paperless-ngx

Most of these are simply docker containers, which end up under the `Docker` Navigation tab.

You can learn more about this in the [Docker wiki section](../docker).

### On-demand tooling

Some "apps", like `restic`, are actually just scripts/tooling, which themselves can still be packaged inside a container, 
executed as-needed (so this way, they have all their dependencies packed in it).

These are usually going to be represented as compose entries, often called either adhoc or as part of a CRON-scheduled
call (example: `restic` backups which are generated every night). They remain "stopped" until needed/active. They should 
NOT be "auto-started", which re-activates the "app" on upon startup or crashing (auto start is mostly reserved for "services").


## The Unraid UI `Plugins` Tab

Some things are meant to be a bit more "native" or more closely integrated to the OS itself due to the
level it needs to operate on, including:

- Tailscale (networking)
- Docker Compose Manager Plus (container management)
- Various Hardware Monitoring (temperature, usage)
- User Scripts (time-scheduled execution of scripts, known as CRON jobs)

These end up as "Plugins". Some plugins also can be installed manually and not directly through the "Apps" Unraid UI tab.

Plugins are usually configured in the `Settings` Unraid UI tab.

## The Unraid UI `Settings` Tab

Settings gives you access to various server-level configurations, along with configuring your various `Plugins`.

It seems like most `Plugins` have their configuration options put here.

