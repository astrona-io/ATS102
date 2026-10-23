#!/usr/bin/env bash
# Creates the starting state for ats-102-lab-030-01:
#   - the project release with podinfo 6.15.0 and the candidate 6.14.1-rc,
#   - no signatures and no key pair, signature enforcement off.
#
# The finished state is NOT created here — producing it is the task.
set -euo pipefail

# ---- shared helpers (same block in every ATS102 script) ----
HARBOR_URL="https://harbor.localtest.me:8443"
HARBOR_HOST="harbor.localtest.me:8443"
ADMIN_USER="admin"
ADMIN_PASSWORD="Harbor12345"
PODINFO="ghcr.io/stefanprodan/podinfo"

# ws CMD...: runs a command in the workstation pod (no stdin).
ws() { kubectl -n workstation exec deploy/workstation -- "$@"; }
# ws_in CMD...: the same, with stdin passed through.
ws_in() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
# wjq FILTER: runs jq in the workstation on stdin.
wjq() { ws_in jq "$@"; }

# harbor_api METHOD PATH [JSON]: calls the Harbor REST API v2.0 as admin.
harbor_api() {
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | ws_in curl -fsS -u "$ADMIN_USER:$ADMIN_PASSWORD" -X "$method" \
      -H 'Content-Type: application/json' --data-binary @- "$HARBOR_URL/api/v2.0$path"
  else
    ws curl -fsS -u "$ADMIN_USER:$ADMIN_PASSWORD" -X "$method" "$HARBOR_URL/api/v2.0$path"
  fi
}

# wait_for_harbor [SECONDS]: waits until /api/v2.0/health reports healthy.
wait_for_harbor() {
  local timeout="${1:-900}" waited=0
  kubectl -n workstation rollout status deployment/workstation --timeout=600s >/dev/null
  while [ "$waited" -lt "$timeout" ]; do
    if [ "$(ws curl -fsS "$HARBOR_URL/api/v2.0/health" 2>/dev/null | wjq -r '.status' 2>/dev/null)" = "healthy" ]; then
      return 0
    fi
    sleep 10; waited=$((waited + 10))
  done
  echo "Harbor did not report healthy within ${timeout}s." >&2
  return 1
}

# regctl_login: signs regctl in to Harbor (idempotent).
regctl_login() {
  ws regctl registry login "$HARBOR_HOST" -u "$ADMIN_USER" -p "$ADMIN_PASSWORD" >/dev/null 2>&1 || true
}

# copy_image SOURCE PROJECT/REPO:TAG: copies the linux/amd64 manifest only, so
# deployment security checks a single image and not an index.
copy_image() {
  regctl_login
  ws regctl image copy --platform linux/amd64 "$1" "$HARBOR_HOST/$2" >/dev/null
}

# ensure_project NAME: creates a private project if it does not exist.
ensure_project() {
  harbor_api GET "/projects/$1" >/dev/null 2>&1 || \
    harbor_api POST /projects "{\"project_name\":\"$1\",\"metadata\":{\"public\":\"false\"}}" >/dev/null
}

# set_project_meta NAME JSON: merges metadata keys into a project.
set_project_meta() { harbor_api PUT "/projects/$1" "{\"metadata\":$2}" >/dev/null; }

# project_meta NAME KEY: prints one metadata value ("" when unset).
project_meta() { harbor_api GET "/projects/$1" | wjq -r ".metadata.$2 // \"\""; }

# artifact_json PROJECT REPO REF: the artifact with scan, SBOM and accessory data.
artifact_json() {
  harbor_api GET "/projects/$1/repositories/$2/artifacts/$3?with_scan_overview=true&with_sbom_overview=true&with_accessory=true&with_tag=true"
}

# scan_status / sbom_status PROJECT REPO REF: Success, Error, Running, ... or None.
scan_status() {
  artifact_json "$1" "$2" "$3" 2>/dev/null | \
    wjq -r '[(.scan_overview // {}) | to_entries[] | .value.scan_status][0] // "None"' 2>/dev/null || echo None
}
sbom_status() {
  artifact_json "$1" "$2" "$3" 2>/dev/null | wjq -r '.sbom_overview.scan_status // "None"' 2>/dev/null || echo None
}

# start_scan / start_sbom PROJECT REPO REF: asks Harbor for a report.
start_scan() { harbor_api POST "/projects/$1/repositories/$2/artifacts/$3/scan" >/dev/null; }
start_sbom() { harbor_api POST "/projects/$1/repositories/$2/artifacts/$3/scan" '{"scan_type":"sbom"}' >/dev/null; }

# wait_for_report PROJECT REPO REF scan|sbom [SECONDS]: prints the final status.
wait_for_report() {
  local timeout="${5:-600}" waited=0 status=None
  while [ "$waited" -lt "$timeout" ]; do
    if [ "$4" = sbom ]; then status="$(sbom_status "$1" "$2" "$3")"; else status="$(scan_status "$1" "$2" "$3")"; fi
    case "$status" in Success|Error|Stopped) break ;; esac
    sleep 10; waited=$((waited + 10))
  done
  echo "$status"
}

# artifact_refs PROJECT REPO: one tag per artifact (digest when untagged).
artifact_refs() {
  harbor_api GET "/projects/$1/repositories/$2/artifacts?page_size=100&with_tag=true" | \
    wjq -r '.[] | select(.type == "IMAGE") | (.tags[0].name // .digest)'
}

# has_accessory PROJECT REPO REF TYPE: true when the artifact has an accessory of TYPE.
has_accessory() {
  [ "$(harbor_api GET "/projects/$1/repositories/$2/artifacts/$3/accessories" | \
    wjq -r --arg type "$4" '[.[] | select(.type == $type)] | length')" -gt 0 ] 2>/dev/null
}

# high_cves PROJECT REPO REF: the unique High and Critical CVE IDs in the report.
high_cves() {
  harbor_api GET "/projects/$1/repositories/$2/artifacts/$3/additions/vulnerabilities" | \
    wjq -r '[.[]? | .vulnerabilities[]? | select(.severity == "High" or .severity == "Critical") | .id] | unique | .[]'
}

# manifest_status PROJECT/REPO REF: HTTP status of a manifest pull as admin.
manifest_status() {
  local token
  token="$(ws curl -fsS -u "$ADMIN_USER:$ADMIN_PASSWORD" \
    "$HARBOR_URL/service/token?service=harbor-registry&scope=repository:$1:pull" | wjq -r '.token')"
  ws curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $token" \
    -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' \
    "$HARBOR_URL/v2/$1/manifests/$2"
}

# image_digest PROJECT/REPO:TAG: the digest of a tag.
image_digest() { regctl_login; ws regctl image digest "$HARBOR_HOST/$1"; }

# cosign_login: signs Cosign in to Harbor (writes /root/.docker/config.json).
cosign_login() {
  ws cosign login "$HARBOR_HOST" -u "$ADMIN_USER" -p "$ADMIN_PASSWORD" >/dev/null 2>&1 || true
}

# make_key_pair DIR PASSWORD: creates cosign.key and cosign.pub in DIR in the workstation.
make_key_pair() {
  ws sh -c "mkdir -p '$1' && cd '$1' && [ -f cosign.key ] || COSIGN_PASSWORD='$2' cosign generate-key-pair >/dev/null"
}

# sign_digest KEY_DIR PASSWORD PROJECT/REPO:TAG: signs the tag's digest without Rekor.
sign_digest() {
  local digest repo="${3%%:*}"
  digest="$(image_digest "$3")"
  cosign_login
  ws env COSIGN_PASSWORD="$2" cosign sign --yes --key "$1/cosign.key" --use-signing-config=false --tlog-upload=false \
    "$HARBOR_HOST/$repo@$digest" >/dev/null
}

# cosign_verifies KEY_DIR PROJECT/REPO:TAG: true when the signature verifies with the public key.
cosign_verifies() {
  cosign_login
  ws cosign verify --key "$1/cosign.pub" --insecure-ignore-tlog=true "$HARBOR_HOST/$2" >/dev/null 2>&1
}

pass() { echo "PASS: $*"; exit 0; }
fail() { echo "FAIL: $*"; exit 1; }
# ---- end of shared helpers ----

wait_for_harbor 900
ensure_project release
copy_image "$PODINFO:6.15.0" release/podinfo:6.15.0
copy_image "$PODINFO:6.14.1" release/podinfo:6.14.1-rc
set_project_meta release '{"enable_content_trust_cosign":"false"}'

echo "[lab] Starting state ready."
