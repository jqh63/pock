# Pock Sync — per-app JSON blob store

Tiny FastAPI service giving the Pock PWAs a server-side copy of their
data: `GET/PUT /pock/<app>` — one JSON blob per app, Bearer token
required on every operation. Designed to run alongside the
[WoL relay](https://github.com/Jqh63/plex-jqh-omv/tree/main/relay) on
the same always-on VM, behind the same Caddy (path route, no new
vhost/cert). The client side lives in `common.js` (§ *Sync* — opt-in,
configured from the hub).

## Why it exists

Pock is "no backend" by design — but `localStorage` is not durable
storage: it vanishes with a browser-data cleanup, no trash bin. This
service is a **scoped exception** to that principle: data goes only to
a personal server you control, only if you opt in from the hub. Without
configuration, nothing is ever sent anywhere.

## API

| Endpoint | Auth | Behaviour |
|---|---|---|
| `GET /pock/health` | none | liveness `{"status":"ok"}` — reveals nothing |
| `GET /pock/<app>` | Bearer | returns the blob verbatim, `404` if none |
| `PUT /pock/<app>` | Bearer | stores the blob (atomic write), JSON object only, size-capped (256 KB default) |

`<app>` must match `[a-z0-9-]{1,32}` (doubles as path-traversal guard).
No listing endpoint. Absent and invalid tokens both get `401` with the
same body (no oracle); the comparison is constant-time. Per-IP
sliding-window rate limit (60 req/min) applied before the token check.

Blob format (written by the client, stored verbatim):

```json
{ "version": 1, "updatedAt": 1718000000000, "data": { "pock-km-vehicles": "…" } }
```

Conflict resolution is client-side last-write-wins per app, using
`updatedAt` (device clock, ms).

## Deploy (mirror of the WoL relay procedure)

As root on the VM:

```bash
useradd --system --home /opt/pock-sync --shell /usr/sbin/nologin pock
mkdir -p /opt/pock-sync /var/lib/pock-sync
chown pock:pock /var/lib/pock-sync && chmod 700 /var/lib/pock-sync
python3 -m venv /opt/pock-sync/venv
/opt/pock-sync/venv/bin/pip install fastapi 'uvicorn[standard]'
# copy app.py to /opt/pock-sync/app.py (via the existing deploy channel)
install -m 0600 pock-sync.env.example /etc/pock-sync.env
# edit /etc/pock-sync.env: POCK_SYNC_TOKEN=$(openssl rand -hex 32)
cp pock-sync.service /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now pock-sync
curl -s localhost:8001/pock/health   # → {"status":"ok"}
```

### Caddy (existing site block of the relay domain)

Add a path route **before** the relay's catch-all `reverse_proxy`:

```caddyfile
handle /pock/* {
	reverse_proxy localhost:8001 {
		header_up -X-Forwarded-For
		header_up X-Real-IP {remote_host}
	}
}
```

And extend the existing CORS headers for the PWA origin:

- `Access-Control-Allow-Methods`: add `PUT`
- `Access-Control-Allow-Headers`: add `Authorization`

(Same rationale as the relay: CORS at the Caddy layer so the headers
are present on Caddy-generated errors too; X-Real-IP is the only
client IP the rate limiter can trust.)

## Token handling

- Generated on the VM (`openssl rand -hex 32`), lives only in
  `/etc/pock-sync.env` (0600) — never in any repo.
- Entered once per device in the PWA hub (stored in `localStorage`; if
  a cache cleanup wipes it, re-enter it — the data itself is on the
  server).
- Revocation = change the env file + restart the unit. Worst case on
  compromise: read/overwrite of low-sensitivity blobs (km logs, book
  lists), restorable from the home backup.

## Backup

The VM is never the sole holder of the data: the home server pulls the
blob files (`/var/lib/pock-sync/*.json`) daily through its existing
read-only deploy channel and feeds them to its regular backup. Losing
the VM loses at most a few hours of sync, never the data.
