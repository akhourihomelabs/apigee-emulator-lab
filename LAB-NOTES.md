# Apigee Local Lab – Notes (Mint, 2026-10-15)

## 1. What runs on Mint (192.168.1.16)

| Container | Image | Ports | Purpose | Touch? |
|---|---|---|---|---|
| `apigee-emulator` | `gcr.io/apigee-release/hybrid/apigee-emulator:2.0.1` | 8080 control, 8998 traffic | Apigee runtime (gateway) | Yes – lab |
| `lab-pgadmin` | `dpage/pgadmin4` | 5050 | pgAdmin | **No** |
| `interview-lab-control-plane` | `kindest/node:v1.34.0` | 127.0.0.1:33125 | kind K8s | **No** |
| 3× `hello-world` (exited) | `hello-world` | – | old leftovers | Leave |

Emulator settings: privileged, DNS 8.8.8.8, restart policy `no`, 1 anonymous volume (`/opt/apigee/apigee-cassandra`).
Images kept locally: emulator 2.0.1 (1.75 GB) and 2.0.0 (1.86 GB).
Parked old setup: `~/labs/apigee/compose.yaml.disabled-20261015`.

## 2. VS Code extensions (remote side, Mint)

| Extension | Needed? | Note |
|---|---|---|
| `googlecloudtools.cloudcode` 2.41.0 | **Yes** | Apigee view, proxy/env/shared-flow wizards |
| `googlecloudtools.datacloud`, `google.geminicodeassist` | Pulled in by Cloud Code | datacloud fails to activate (old Jupyter) – harmless for Apigee |
| `ms-toolsai.jupyter` (+4 helpers) | Pulled in by datacloud | 2025.9 needs VS Code 1.105; server is 1.104 → old 2023.8 loads |
| `anthropic.claude-code` | Yes | assistant |
| `github.copilot`, `copilot-chat` | Optional | no Copilot access on this account |

No Google sign-in, no gcloud, no Apigee org. No web dashboard locally – Cloud Code + files are the UI.

## 3. Workspace files (`~/labs/myapigeeproxy`)

```
emulator.sh      start | stop | status | deploy [env]
deploy.sh        zips src/main/apigee and POSTs to :8080/v1/emulator/deploy?environment=<env>
src/main/apigee/
  apiproxies/hello/apiproxy/
    hello.xml                 proxy name/description
    proxies/default.xml       BasePath (/hello), flows, which policies run, RouteRule
    policies/AM-Hello.xml     policy (AssignMessage → JSON response)
    targets/*.xml             (add when calling a backend)
  environments/dev/
    deployments.json          WHICH proxies/shared flows deploy: {"proxies":["hello"]}
    targetservers.json, flowhooks.json, keystores/   (later: mTLS, shared flows)
  sharedflows/                (later)
```

**Change a proxy:** edit XML → `./emulator.sh deploy` → test.
**Add a proxy:** create it (APIGEE view → apiproxies → +) → add its name to `environments/dev/deployments.json` → deploy.

## 4. Hello world – test

```bash
curl -i http://localhost:8998/hello/anything
# 200 {"message":"hello from Apigee emulator","path":"/anything","verb":"GET"}
```
From the Windows laptop: VS Code → **Ports** tab → forward 8998 (and 8080) → `http://localhost:8998/hello`.

## 5. Start / stop

```bash
cd ~/labs/myapigeeproxy
./emulator.sh start    # starts (or creates) container, waits ~30 s, redeploys env dev
./emulator.sh status   # container state + deployed proxies
./emulator.sh stop     # stops container (kept, not removed)
```
Raw Docker equivalent: `docker start|stop apigee-emulator` – but then run `./deploy.sh dev` yourself.

## 6. Persistence (important)

- **Tested:** `docker restart` → deployed proxies are **gone** (tree `[]`, `/hello` → 404).
- Source of truth = files in `src/main/apigee`. They are on the Mint disk and are never lost by stop/start.
- So "persistence" = always start with `./emulator.sh start` (auto-redeploy).
- Container is not auto-started after reboot (restart policy `no`) – run `./emulator.sh start`.
- Recommended: `git init` this folder to version your proxies.

## 7. Known log noise (emulator 2.0.1)

`api_security_actions_contract_ref does not exist`, `Datastore Error`, `RepositoryFactory is not aware…`,
`Address already in use`, `NoClassDefFoundError jnr/posix`, `Invalid forward proxy`.
Proxy deploy + traffic work despite these. Not yet verified: API-security features.

## 8. Lab roadmap

1. Shared flow `sf-security` (SpikeArrest + logging) via flow hook
2. Keycloak + VerifyJWT / OAuth2
3. Southbound mTLS → Spring Boot claims API (keystores, target server)
4. Northbound mTLS: NGINX (client cert) → emulator

Real Apigee UI only with an eval org (60 days, billing account required) – later, planned.
