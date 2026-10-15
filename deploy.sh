#!/usr/bin/env bash
# Deploy an environment from this Cloud Code workspace to the local Apigee emulator.
# Usage: ./deploy.sh [env]   (default env: dev)
set -euo pipefail
ENV="${1:-dev}"
ROOT="$(cd "$(dirname "$0")" && pwd)/src/main/apigee"
[ -f "$ROOT/environments/$ENV/deployments.json" ] || { echo "Missing $ROOT/environments/$ENV/deployments.json"; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
(cd "$ROOT" && python3 -I -m zipfile -c "$TMP/contract.zip" apiproxies environments sharedflows)
curl -sS -X POST -H 'Content-Type: zip' --data-binary @"$TMP/contract.zip" \
  "http://localhost:8080/v1/emulator/deploy?environment=$ENV"
echo
