# Docker on Unraid

Unraid provides a graphical interface for managing Docker, so you generally don't have to manually construct Docker commands.

When you add a Docker application in Unraid, you're essentially telling Docker:

> "Run this image, and configure it this way."

For example, you might configure:

```text
Image:
    my-app:latest

Port:
    8080 → 8080

Appdata:
    /mnt/user/appdata/my-app
        → /config
```

Unraid takes those settings and uses Docker to create the container.

---

## Unraid templates

Unraid's **Docker templates** are essentially saved configuration information for a container.

A template can specify things such as:

- Which Docker image to use
- Which ports to expose
- Which folders to make available to the container
- Environment variables
- Other Docker settings

For example:

```text
Template
   │
   ├── Image: my-app
   ├── Port: 8080 → 8080
   ├── /config → /mnt/user/appdata/my-app
   └── Other settings
          │
          ▼
       Docker
          │
          ▼
      Container
```

The template isn't the application itself. **The image contains the application; the template tells Unraid how you want that application to be run.**

This is why the template is useful when recreating a container: it preserves the configuration needed to set it up again.

---

## Appdata and persistent storage

One of the most important concepts when using Docker on Unraid is that the container itself generally isn't where you want important application data to live.

Instead, Unraid can map a folder on the server into the container.

For example:

```text
Unraid
│
├── /mnt/user/appdata/my-app
│          │
│          │ mapped into
│          ▼
│      /config
│
└── Docker container
           │
           └── My application
```

The application sees `/config` as a normal folder, but the actual files are stored in Unraid's `appdata` share.

This means the application's important data remains on the server even if the Docker container itself needs to be recreated.

This is particularly useful when updating or replacing containers: **the application software comes from the image, while the application's persistent data lives on Unraid.**

---

# The overall Unraid model

Putting everything together:

```text
                         Unraid
                            │
                          Docker
                            │
              ┌─────────────┴─────────────┐
              │                           │
         Docker image                Configuration
       "What is the app?"        "How should it run?"
              │                           │
              └─────────────┬─────────────┘
                            ▼
                       Container
                    "Running app"
                            │
              ┌─────────────┼─────────────┐
              │             │             │
            Ports        Networking    Storage
              │             │             │
              ▼             ▼             ▼
           Network       Other         Unraid
           access       containers     appdata
```

The simplest mental model is:

> **Docker image:** the packaged application and the software it needs.
>
> **Docker:** the software that runs and manages containers.
>
> **Container:** a running, configured instance of an image.
>
> **Ports:** determine how network traffic gets into and out of the application.
>
> **Docker networks:** allow containers to communicate with each other.
>
> **Unraid template:** tells Unraid/Docker how to configure the container.
>
> **Appdata:** stores the application's persistent data outside the container.

This separation is what makes Docker particularly convenient for a server like Unraid. You can treat applications as relatively self-contained packages while still being able to configure how they connect to the network, where their data lives, and how they interact with other applications.
