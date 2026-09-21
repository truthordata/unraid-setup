# Custom DNS

One benefit

# Split DNS Architecture

## Overview

The goal of this setup is to allow the **same domain name** to work both inside and outside the home network, while resolving to different IP addresses depending on where the client is located.

For example:

```text
app.mydomain.com
```

resolves to:

- **LAN clients:** `192.168.1.100` — the Unraid server's local IP
- **Remote clients:** `100.x.x.x` — the Unraid server's Tailscale IP

The client doesn't need to know which network path to use. It simply uses the same hostname.

---

## 1. Client Requests the Domain

When a client wants to access:

```text
https://app.mydomain.com
```

it first performs a DNS lookup for:

```text
app.mydomain.com
```

The DNS server used by the client determines which IP address it receives.

---

## 2. Clients on the Home LAN

Clients on the home network use **Pi-hole** as their DNS resolver.

Pi-hole has a local DNS rule that resolves the domain to the Unraid server's LAN address:

```text
app.mydomain.com → 192.168.1.100
```

The traffic therefore stays entirely on the local network:

```text
Client
  │
  │ DNS query
  ▼
Pi-hole
  │
  │ 192.168.1.100
  ▼
Unraid
```

There is **no Tailscale involvement** in the local path.

---

## 3. Remote Clients

When the client is away from the home network, it doesn't use the local Pi-hole DNS server.

Instead, the domain is resolved through **Cloudflare's public DNS**:

```text
app.mydomain.com → 100.x.x.x
```

The returned address is the Unraid server's **Tailscale IP**.

The client then connects to that address through Tailscale:

```text
Remote Client
  │
  │ DNS query
  ▼
Cloudflare
  │
  │ 100.x.x.x
  ▼
Tailscale
  │
  ▼
Unraid
```

This allows the service to remain inaccessible from the public Internet while still being reachable remotely through the tailnet.

---

## 4. Both Paths Reach the Same Unraid Server

At this point, the two network paths have converged:

```text
             app.mydomain.com
                     │
          ┌──────────┴──────────┐
          │                     │
       At home                Remote
          │                     │
      Pi-hole              Cloudflare
          │                     │
   192.168.1.100             100.x.x.x
          │                     │
          ▼                     ▼
       ┌───────────────────────────┐
       │       Unraid Server       │
       │                           │
       │ LAN:      192.168.1.100   │
       │ Tailscale: 100.x.x.x      │
       └─────────────┬─────────────┘
                     │
                     ▼
                  NPM
```

The important point is that **DNS determines how the client reaches Unraid; it does not determine which application ultimately receives the request.**

---

## 5. Nginx Proxy Manager Determines the Application

Once the request reaches Unraid, **Nginx Proxy Manager (NPM)** receives the HTTP/HTTPS request.

NPM listens on the standard web ports:

```text
80  → HTTP
443 → HTTPS
```

The original hostname is still present in the HTTP request. For example:

```text
Host: app.mydomain.com
```

NPM uses that hostname to determine which **Proxy Host** configuration should handle the request.

For example:

```text
app.mydomain.com
        ↓
NPM
        ↓
192.168.1.100:8000
```

Another hostname can map somewhere completely different:

```text
photos.mydomain.com
        ↓
NPM
        ↓
192.168.1.100:2283
```

So DNS gets the request **to the server**, while NPM gets the request **to the correct application**.

---

## 6. The Complete Flow

### At home

```text
Client
  ↓
DNS: Pi-hole
  ↓
192.168.1.100
  ↓
Unraid
  ↓
NPM :443
  ↓
Hostname-based Proxy Host
  ↓
Application IP:Port
```

### Remotely

```text
Client
  ↓
DNS: Cloudflare
  ↓
100.x.x.x
  ↓
Tailscale
  ↓
Unraid
  ↓
NPM :443
  ↓
Hostname-based Proxy Host
  ↓
Application IP:Port
```

---

## 7. Why This Is Useful

This arrangement gives you a **single consistent namespace** for your services.

You can always use:

```text
https://app.mydomain.com
https://photos.mydomain.com
https://something.mydomain.com
```

regardless of whether you're:

- On your home LAN
- Connected remotely through Tailscale

You don't have to remember:

```text
192.168.1.100:8000
100.x.x.x:8000
```

or change URLs depending on where you are.

The separation of responsibilities is also clean:

| Component | Responsibility |
|---|---|
| **Pi-hole** | Local DNS resolution |
| **Cloudflare** | Public DNS resolution |
| **Tailscale** | Secure remote network path |
| **Unraid** | Hosts the applications |
| **NPM** | HTTPS termination and hostname → application IP:port routing |
| **Applications** | Actually serve the requested content |

The key concept is:

> **DNS decides which server IP the client connects to. NPM decides which application on that server handles the request.**
