#!/usr/bin/env bash
# Atomically deploy a validated canonical database and public exports to the VPS.
set -euo pipefail

: "${VPS_SSH_PRIVATE_KEY:?VPS_SSH_PRIVATE_KEY is required}"
: "${VPS_SSH_KNOWN_HOSTS:?VPS_SSH_KNOWN_HOSTS is required}"
: "${VPS_HOST:?VPS_HOST is required}"
: "${VPS_USER:?VPS_USER is required}"
: "${VPS_PORT:=22}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"
: "${GITHUB_RUN_ATTEMPT:?GITHUB_RUN_ATTEMPT is required}"

if [[ ! "$VPS_HOST" =~ ^[A-Za-z0-9.-]+$ ]] \
  || [[ ! "$VPS_USER" =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ]] \
  || [[ ! "$VPS_PORT" =~ ^[0-9]{1,5}$ ]] \
  || ((10#$VPS_PORT < 1 || 10#$VPS_PORT > 65535)) \
  || [[ ! "$GITHUB_RUN_ID" =~ ^[0-9]+$ ]] \
  || [[ ! "$GITHUB_RUN_ATTEMPT" =~ ^[0-9]+$ ]]; then
  echo "VPS deployment configuration is missing or invalid." >&2
  exit 2
fi

for required_file in \
  data/opportunities.db \
  data/exports/open-opportunities.csv \
  data/exports/open-opportunities.json; do
  if [[ ! -s "$required_file" ]]; then
    echo "Validated deployment file is missing or empty: $required_file" >&2
    exit 1
  fi
done

ssh_dir=${CANONICAL_STATE_SSH_DIR:-$HOME/.ssh}
private_key="$ssh_dir/id_ed25519"
known_hosts="$ssh_dir/known_hosts"
ssh_target=""
ssh_options=()
remote_database_upload=""
remote_previous_upload=""
remote_csv_upload=""
remote_json_upload=""
cleanup() {
  # Remove execution-specific remote uploads after partial transfer or deployment failures.
  if [[ -n "$ssh_target" && -n "$remote_database_upload" && -s "$private_key" ]]; then
    # shellcheck disable=SC2029
    ssh "${ssh_options[@]}" "$ssh_target" \
      "rm -f '$remote_database_upload' '$remote_previous_upload' '$remote_csv_upload' '$remote_json_upload'" \
      >/dev/null 2>&1 || true
  fi
  rm -f "$private_key" "$known_hosts"
}
trap cleanup EXIT

install -d -m 700 "$ssh_dir"
printf '%s\n' "$VPS_SSH_PRIVATE_KEY" >"$private_key"
printf '%s\n' "$VPS_SSH_KNOWN_HOSTS" >"$known_hosts"
chmod 600 "$private_key" "$known_hosts"

remote_dir="/srv/european-tech-opportunities-2027/data"
remote_database="$remote_dir/opportunities.db"
remote_previous="$remote_dir/opportunities.db.previous"
remote_export_dir="$remote_dir/exports"
remote_csv="$remote_export_dir/open-opportunities.csv"
remote_json="$remote_export_dir/open-opportunities.json"
execution_id="${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
remote_database_upload="$remote_dir/.opportunities-${execution_id}.db.upload"
remote_previous_upload="$remote_dir/.opportunities-${execution_id}.previous.upload"
remote_csv_upload="$remote_dir/.open-opportunities-${execution_id}.csv.upload"
remote_json_upload="$remote_dir/.open-opportunities-${execution_id}.json.upload"
remote_lock="/srv/european-tech-opportunities-2027/.database-deploy.lock"

database_sha=$(sha256sum data/opportunities.db | cut -d ' ' -f 1)
csv_sha=$(sha256sum data/exports/open-opportunities.csv | cut -d ' ' -f 1)
json_sha=$(sha256sum data/exports/open-opportunities.json | cut -d ' ' -f 1)
ssh_target="${VPS_USER}@${VPS_HOST}"
ssh_options=(
  -i "$private_key"
  -p "$VPS_PORT"
  -o BatchMode=yes
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=yes
  -o "UserKnownHostsFile=$known_hosts"
  -o ConnectTimeout=20
  -o ConnectionAttempts=1
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=2
)
scp_options=(
  -i "$private_key"
  -P "$VPS_PORT"
  -o BatchMode=yes
  -o IdentitiesOnly=yes
  -o StrictHostKeyChecking=yes
  -o "UserKnownHostsFile=$known_hosts"
  -o ConnectTimeout=20
  -o ConnectionAttempts=1
  -o ServerAliveInterval=15
  -o ServerAliveCountMax=2
)

scp "${scp_options[@]}" data/opportunities.db "${ssh_target}:${remote_database_upload}"
scp "${scp_options[@]}" \
  data/exports/open-opportunities.csv "${ssh_target}:${remote_csv_upload}"
scp "${scp_options[@]}" \
  data/exports/open-opportunities.json "${ssh_target}:${remote_json_upload}"

# Validated remote paths are intentionally expanded before invoking SSH.
# shellcheck disable=SC2029
remote_hashes=$(ssh "${ssh_options[@]}" "$ssh_target" \
  "sha256sum '$remote_database_upload' '$remote_csv_upload' '$remote_json_upload' | cut -d ' ' -f 1")
expected_hashes=$(printf '%s\n%s\n%s\n' "$database_sha" "$csv_sha" "$json_sha")
if [[ "$expected_hashes" != "$remote_hashes" ]]; then
  # shellcheck disable=SC2029
  ssh "${ssh_options[@]}" "$ssh_target" \
    "rm -f '$remote_database_upload' '$remote_previous_upload' '$remote_csv_upload' '$remote_json_upload'"
  echo "One or more uploaded checksums do not match." >&2
  exit 1
fi

# shellcheck disable=SC2029
ssh "${ssh_options[@]}" "$ssh_target" \
  "DATABASE_IMPORT='$remote_database_upload' PREVIOUS_IMPORT='$remote_previous_upload' CSV_IMPORT='$remote_csv_upload' JSON_IMPORT='$remote_json_upload' DATABASE_FILE='$remote_database' PREVIOUS_FILE='$remote_previous' EXPORT_DIR='$remote_export_dir' CSV_FILE='$remote_csv' JSON_FILE='$remote_json' LOCK_FILE='$remote_lock' DATABASE_SHA='$database_sha' CSV_SHA='$csv_sha' JSON_SHA='$json_sha' bash -s" <<'REMOTE'
set -euo pipefail
trap 'rm -f "$DATABASE_IMPORT" "$PREVIOUS_IMPORT" "$CSV_IMPORT" "$JSON_IMPORT"' EXIT

exec 9>"$LOCK_FILE"
flock -n 9

test "$(sha256sum "$DATABASE_IMPORT" | cut -d " " -f 1)" = "$DATABASE_SHA"
test "$(sha256sum "$CSV_IMPORT" | cut -d " " -f 1)" = "$CSV_SHA"
test "$(sha256sum "$JSON_IMPORT" | cut -d " " -f 1)" = "$JSON_SHA"

if [[ -f "$DATABASE_FILE" ]]; then
  cp -p "$DATABASE_FILE" "$PREVIOUS_IMPORT"
  mv -f "$PREVIOUS_IMPORT" "$PREVIOUS_FILE"
fi

mkdir -p "$EXPORT_DIR"
chgrp opportunities-site "$EXPORT_DIR" "$DATABASE_IMPORT" "$CSV_IMPORT" "$JSON_IMPORT"
chmod 750 "$EXPORT_DIR"
chmod 660 "$DATABASE_IMPORT"
chmod 640 "$CSV_IMPORT" "$JSON_IMPORT"
rm -f "${DATABASE_FILE}-wal" "${DATABASE_FILE}-shm" "${DATABASE_FILE}-journal"
mv "$DATABASE_IMPORT" "$DATABASE_FILE"
mv "$CSV_IMPORT" "$CSV_FILE"
mv "$JSON_IMPORT" "$JSON_FILE"

test "$(sha256sum "$DATABASE_FILE" | cut -d " " -f 1)" = "$DATABASE_SHA"
test "$(sha256sum "$CSV_FILE" | cut -d " " -f 1)" = "$CSV_SHA"
test "$(sha256sum "$JSON_FILE" | cut -d " " -f 1)" = "$JSON_SHA"
REMOTE
