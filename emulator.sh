#!/usr/bin/env bash
# Start/stop the local Apigee emulator. Deployments do NOT survive a restart,
# so "start" waits until the emulator is ready and redeploys from src/main/apigee.
# Usage: ./emulator.sh start|stop|status|deploy [env]   (default env: dev)
set -euo pipefail
NAME=apigee-emulator
IMAGE=gcr.io/apigee-release/hybrid/apigee-emulator:2.0.1
ENV="${2:-dev}"
DIR="$(cd "$(dirname "$0")" && pwd)"

wait_ready() {
  for _ in $(seq 1 36); do
    curl -s -m 3 http://localhost:8080/v1/emulator/version >/dev/null && { sleep 5; return 0; }
    sleep 5
  done
  echo "Emulator not ready after 3 min"; exit 1
}

case "${1:-}" in
  start)
    if docker container inspect "$NAME" >/dev/null 2>&1; then
      docker start "$NAME" >/dev/null
    else
      docker run -d --name "$NAME" --privileged --dns 8.8.8.8 -e XTERM=xterm-256color \
        -p 8080:8080 -p 8998:8998 "$IMAGE" >/dev/null
    fi
    wait_ready
    "$DIR/deploy.sh" "$ENV"
    ;;
  stop)   docker stop "$NAME" >/dev/null && echo stopped ;;
  status) docker ps -a --filter "name=^${NAME}$" --format '{{.Names}} {{.Status}}'
          curl -s http://localhost:8080/v1/emulator/tree || echo "control API not reachable"; echo ;;
  deploy) "$DIR/deploy.sh" "$ENV" ;;
  *) echo "Usage: $0 start|stop|status|deploy [env]"; exit 1 ;;
esac
