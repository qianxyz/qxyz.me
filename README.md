# qxyz.me

Homepage and deployment hub for [qxyz.me](https://qxyz.me) and its app
subdomains. Each app lives in its own repo with a `Dockerfile` and a
local-dev `compose.yaml`; this repo owns everything about how they are
served in production.

## Layout

    public/                  # homepage static files (served by caddy)
    deploy/
    ├── compose.yaml         # hub stack: cloudflared (tunnel) + caddy
    ├── Caddyfile            # qxyz.me → homepage; <app>.qxyz.me → app container
    ├── apps/<repo>.yaml     # per-app prod compose override
    └── deploy.sh            # deploy.sh <repo>: git pull + compose up --build

## How it works

    Cloudflare (DNS + TLS) → tunnel → cloudflared → caddy → app containers
                 (one shared external docker network: `web`)

- Cloudflare terminates TLS and forwards `qxyz.me` + `*.qxyz.me` into the
  tunnel; nothing listens on public ports on the host.
- Caddy routes each subdomain to a container by compose service name
  (convention: service name = repo name).
- App repos are deployment-agnostic: `docker compose up` in any of them
  gives a local instance. The overrides in `deploy/apps/` adapt them for
  production (join the `web` network, drop host ports, restart policy).

## Adding an app

1. Give the app repo a `Dockerfile` and a `compose.yaml` whose public
   service is named after the repo.
2. Add a site block to `deploy/Caddyfile` and an override in
   `deploy/apps/<repo>.yaml`.
3. Add a card to the homepage in `public/index.html`.
4. On the server: clone the repo under `/srv`, run
   `deploy/deploy.sh <repo>`, and reload caddy:
   `docker compose -f deploy/compose.yaml exec caddy caddy reload --config /etc/caddy/Caddyfile`

## Server bootstrap

One-time setup on a fresh host: install docker,
`docker network create web`, clone the repos under `/srv`, create a
Cloudflare tunnel (`cloudflared tunnel create` + `tunnel route dns` for
the apex and wildcard) and place its credentials JSON at
`deploy/cloudflared/credentials.json` (git-ignored; the tunnel id in
`deploy/cloudflared/config.yml` must match), then
`docker compose -f deploy/compose.yaml up -d` and `deploy.sh` each app.
