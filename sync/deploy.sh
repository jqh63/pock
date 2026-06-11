#!/usr/bin/env bash
# deploy.sh — deploy pock-sync's code/unit to the VM through the existing
# forced-command channel (same alias as the WoL relay).
#
# Pipes app.py + pock-sync.service over stdin to the VM-side dispatch.sh,
# then triggers apply-pock-sync + pock-sync-status.
#
# Prerequisites:
#   - the `wol-relay-deploy` SSH alias configured on the deploying host
#   - dispatch.sh + sudoers on the VM carrying the pock-sync verbs
#   - one-shot bootstrap done (sync/bootstrap-pock-sync.sh)
#
# Usage:
#   bash sync/deploy.sh
#   WOL_RELAY_ALIAS=other-alias bash sync/deploy.sh
#
# Exit codes: 0 OK, 1 push/apply failed, 2 status KO post-restart.

set -euo pipefail

ALIAS="${WOL_RELAY_ALIAS:-wol-relay-deploy}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[deploy] push app.py ..."
ssh "$ALIAS" push-pock-sync-app < "$DIR/app.py"

echo "[deploy] push pock-sync.service ..."
ssh "$ALIAS" push-pock-sync-service < "$DIR/pock-sync.service"

echo "[deploy] apply-pock-sync ..."
ssh "$ALIAS" apply-pock-sync

echo "[deploy] status ..."
if ssh "$ALIAS" pock-sync-status; then
  echo "[deploy] DONE — pock-sync restarted, /pock/health OK"
else
  echo "[deploy] WARN — status KO post-restart, investigate VM side (logs-pock-sync)" >&2
  exit 2
fi
