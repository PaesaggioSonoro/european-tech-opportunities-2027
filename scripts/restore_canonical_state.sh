#!/usr/bin/env bash
# Restore canonical state from the restricted snapshot store, with a verified live fallback.
set -euo pipefail

: "${VPS_BACKUP_SSH_PRIVATE_KEY:?VPS_BACKUP_SSH_PRIVATE_KEY is required}"
: "${VPS_SSH_KNOWN_HOSTS:?VPS_SSH_KNOWN_HOSTS is required}"
: "${VPS_BACKUP_HOST:?VPS_BACKUP_HOST is required}"
: "${VPS_BACKUP_USER:=opportunities-backup}"
: "${VPS_BACKUP_PORT:=22}"
: "${CANONICAL_STATE_DATABASE:=data/opportunities.db}"

ssh_dir=${CANONICAL_STATE_SSH_DIR:-$HOME/.ssh}
backup_key="$ssh_dir/id_backup_ed25519"
live_key="$ssh_dir/id_ed25519"
known_hosts="$ssh_dir/known_hosts"
bootstrap_download="${CANONICAL_STATE_DATABASE}.bootstrap-${GITHUB_RUN_ID:-local}"

cleanup() {
  rm -f "$backup_key" "$live_key" "$known_hosts" "$bootstrap_download"
}
trap cleanup EXIT

install -d -m 700 "$ssh_dir"
printf '%s\n' "$VPS_BACKUP_SSH_PRIVATE_KEY" >"$backup_key"
printf '%s\n' "$VPS_SSH_KNOWN_HOSTS" >"$known_hosts"
chmod 600 "$backup_key" "$known_hosts"

verify_database() {
  local database_path=$1
  uv run python - "$database_path" <<'PY'
import sys
from pathlib import Path

from opportunities.database.snapshots import SnapshotError, inspect_database

try:
    inspect_database(Path(sys.argv[1]))
except (OSError, SnapshotError) as exc:
    raise SystemExit(f"Canonical state candidate failed recovery checks: {exc}") from exc
PY
}

VPS_BACKUP_SSH_KEY="$backup_key" \
VPS_BACKUP_KNOWN_HOSTS="$known_hosts" \
  bash scripts/canonical_state_store.sh restore

if [[ -s "$CANONICAL_STATE_DATABASE" ]]; then
  if verify_database "$CANONICAL_STATE_DATABASE"; then
    echo "Using canonical state restored from restricted VPS snapshot storage."
    exit 0
  fi
  echo "Discarding an invalid existing candidate before the reviewed live-database fallback." >&2
  rm -f "$CANONICAL_STATE_DATABASE"
fi

: "${VPS_SSH_PRIVATE_KEY:?VPS_SSH_PRIVATE_KEY is required when durable snapshot state is absent}"
: "${VPS_HOST:?VPS_HOST is required when durable snapshot state is absent}"
: "${VPS_USER:?VPS_USER is required when durable snapshot state is absent}"
: "${VPS_PORT:=22}"

if [[ ! "$VPS_HOST" =~ ^[A-Za-z0-9.-]+$ ]] \
  || [[ ! "$VPS_USER" =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ]] \
  || [[ ! "$VPS_PORT" =~ ^[0-9]{1,5}$ ]] \
  || ((10#$VPS_PORT < 1 || 10#$VPS_PORT > 65535)); then
  echo "VPS bootstrap configuration is missing or invalid." >&2
  exit 2
fi

printf '%s\n' "$VPS_SSH_PRIVATE_KEY" >"$live_key"
chmod 600 "$live_key"
mkdir -p "$(dirname "$CANONICAL_STATE_DATABASE")"
rm -f "$bootstrap_download"

ssh \
  -i "$live_key" \
  -p "$VPS_PORT" \
  -o BatchMode=yes \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=yes \
  -o "UserKnownHostsFile=$known_hosts" \
  -o ConnectTimeout=20 \
  -o ConnectionAttempts=1 \
  -o ServerAliveInterval=15 \
  -o ServerAliveCountMax=2 \
  "${VPS_USER}@${VPS_HOST}" \
  "cat /srv/european-tech-opportunities-2027/data/opportunities.db" \
  >"$bootstrap_download"

verify_database "$bootstrap_download"
mv -f "$bootstrap_download" "$CANONICAL_STATE_DATABASE"
echo "Bootstrapped canonical state from the reviewed live VPS database."
