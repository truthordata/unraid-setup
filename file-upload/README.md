# What is `file-upload`?

I set this app up as a way for users to upload content to my server using a UI
where you could drag and drop files from your desktop to the browser UI.

It normally is a more general purpose file browser, only I set strict permissions
where users only have access to the upload folder and can only add new files, nothing else.

# Setup

## Make your folders

```shell
mkdir -p /mnt/user/appdata/file-upload
chown -R 1000:1000 /mnt/user/appdata/file-upload
chmod -R 775 /mnt/user/appdata/file-upload
```

## Install the App

Find "FileBrowser-PNP" in the Apps tab of Unraid and click "info" -> "install".

You can rename it to "file-upload" on the template/setup screen.

**IMPORTANT**: currently has bug where there's superfluous DB paths in the template: 
just use the suggested env var.



# Setting Up Permissions

**NOTE**: These commands, which access the DB, must be run when container is down, as
the db is otherwise locked while the container is running.

Once installed, you can stop the container by going to the UI, clicking the icon/portrait on the left side, 
which brings up a context menu, and select "stop".

## turn off needing to log in

To make user access easy, we disable the need for logging in:

```bash
docker run --rm --volumes-from file-upload it filebrowser/filebrowser \
  --database /config/filebrowser.db \
  config set --auth.method=noauth
```

This basically makes it to where it defaults to using the default (admin)
user for everyone, which is why we...


## limit privs for the admin user

This is how we limit the default (admin) user to only be able to create new files:

```bash
docker run --rm --volumes-from file-upload it filebrowser/filebrowser \
  --database /config/filebrowser.db \
  users update \
  --perm.admin=false \
  --perm.create=true \
  --perm.modify=false \
  --perm.rename=false \
  --perm.delete=false \
  --perm.share=false \
  --perm.execute=false \
  --perm.download=false \
  1
```

(Yes, include the 1, which is the admin user)
(also yes, set admin to false, cuz otherwise it overrides the other settings).

## Setting a higher session timeout

The default session timeout is 2 hours; you can extend it to whatever time you want.

Here I set it to 16 hours:

```bash
docker run --rm --volumes-from file-upload it filebrowser/filebrowser \
  --database /config/filebrowser.db \
  config set --tokenExpirationTime 16h
```