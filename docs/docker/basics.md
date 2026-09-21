# WTF is Docker?

At a fundamental level, **Docker is a way of packaging an application together with the software it needs to run**.

A simple example is a web application. Normally, running that application might require:

- The application itself
- A particular version of Python
- Python libraries the application depends on
- Other software or libraries it expects to be present

If you install all of that directly on a computer, you have to make sure everything is set up correctly. Another computer might have different versions installed, or might be missing something entirely.

Docker lets the application developer package the application and its required software into a **container image**.

The idea is essentially:

> **Application + what it needs to run = portable package**

That package can then be run on another computer using Docker without having to manually recreate the application's environment.

## Designed to be portable

This gives Docker one of its biggest advantages: **the application can behave consistently from machine to machine**.

For example:

```text
Computer A                  Computer B
    │                           │
  Docker                      Docker
    │                           │
    ▼                           ▼
My Web App                  My Web App
    │                           │
Application +              Application +
its dependencies           its dependencies
```

The computers themselves may be configured differently, but the application is being provided with essentially the same software environment.

Containers are also designed to be relatively lightweight. Unlike a virtual machine, you aren't packaging an entire separate computer inside the container. You're primarily packaging the application and the software it needs.

---

## Images vs. containers

There are two important terms to understand:

**An image** is the packaged application.

**A container** is an instance of that image that Docker is actually running.

A simple analogy is:

> **Image = packaged application**  
> **Container = running application**

For example, an application developer might provide an image for a photo management application. You give that image to Docker and tell it to run it, and Docker creates a container from the image.

```text
Photo App Image
       │
       ▼
   Container
       │
       ▼
 Photo App running
```

The image contains the application software. The container is the running instance that you interact with.

---

## Where Docker comes in

**Docker is the software that manages all of this.**

It takes an image and uses it to create and run a container. It also handles things such as connecting the container to the network, giving it access to selected folders, and applying configuration settings.

Conceptually:

```text
Docker
  │
  ├── Image
  │     │
  │     ▼
  │   Container
  │
  ├── Networking
  │
  ├── Storage
  │
  └── Configuration
```

So when someone says "I'm running this application in Docker," they generally mean that Docker is running a container created from an image containing that application.

---

## Containers can still be configured

An image provides the application, but that doesn't mean every instance of that application has to be configured identically.

For example, imagine an image containing a web application that listens for connections on port `8080`.

You might configure one container to make that application available on port `8080` on the server:

```text
Server port 8080
       │
       ▼
Container port 8080
       │
       ▼
   Web application
```

You could also give the container access to a particular folder on the server:

```text
Server
/mnt/user/appdata/myapp
        │
        ▼
   Container
     /config
```

And you might provide environment variables or other settings that tell the application how you want it configured.

The important distinction is:

> **The image provides the application. The container is the configured instance of that application.**

This is what makes a generic Docker image useful on many different servers.

---

## Docker networking and ports

Networking is another important part of running containers, but the basic idea is fairly simple.

A container has its own network identity within Docker. Other containers can communicate with it through Docker's networking system, and Docker can also make a container's application accessible from the host or from other devices on the network.

### Container ports

Suppose an application inside a container listens on port `8080`.

That doesn't necessarily mean you access it by typing `server-ip:8080`.

Docker can map a port on the server to the port inside the container:

```text
Your computer
      │
      │ http://server:8080
      ▼
Unraid server
      │
      │ port 8080
      ▼
Docker container
      │
      │ port 8080
      ▼
Application
```

You could instead map server port `9000` to the application's container port `8080`:

```text
Server port 9000
       │
       ▼
Container port 8080
       │
       ▼
 Application
```

The application itself still listens on `8080`; Docker is simply forwarding traffic from the server's `9000` port to it.

### Docker networks

Docker can also put multiple containers on the same Docker network.

For example:

```text
             Docker network
          ┌───────────────────┐
          │                   │
      Web App              Database
          │                   │
          └───────────────────┘
```

The web application can communicate with the database over that Docker network without necessarily exposing the database directly to the rest of your home network.

This is particularly useful for applications that consist of multiple containers, such as a web application that uses a separate database container.

You don't need to understand the details of Docker's networking implementation to work with most applications. At a practical level, the important concepts are:

- **Container port:** the port the application listens on inside the container.
- **Host port:** the port Docker exposes on the server.
- **Port mapping:** connects the host port to the container port.
- **Docker network:** allows containers to communicate with each other.

