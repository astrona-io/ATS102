# Overview: Stop Vulnerable Artifacts From Being Pulled (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies and scans some artifacts, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `regctl`, the `harbor` command-line tool, `cosign`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`inventory`** with two scanned artifacts, both `linux/amd64` only:

  | Artifact | What it is |
  | --- | --- |
  | `inventory/podinfo:6.0.0` | An old release with High and Critical findings |
  | `inventory/podinfo:6.15.0` | A recent release |

- Vulnerability prevention is off, and the system CVE allowlist is empty.

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell. `api` calls the Harbor REST API as `admin`. `high_cves` prints the High and Critical CVE IDs of one artifact, given as `<project> <tag>`. `try_pull` pulls one manifest, given as `<project> <tag>`, and says whether Harbor allowed it.

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
high_cves() {
  api "$API/projects/$1/repositories/podinfo/artifacts/$2/additions/vulnerabilities" \
    | jq -r '[.[].vulnerabilities[] | select(.severity == "High" or .severity == "Critical") | .id] | unique | .[]'
}
try_pull() {
  regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345 >/dev/null 2>&1
  regctl manifest get "harbor.localtest.me:8443/$1/podinfo:$2" > /dev/null && echo "$1/podinfo:$2 allowed"
}
```

Use them like this: `high_cves inventory 6.0.0 | wc -l`, `try_pull inventory 6.0.0`.

## Practice tasks

- Turn on prevention with each threshold in turn, `critical`, `high`, `medium`, `low`, and predict from the report which tag pulls before you run `try_pull`.
- Copy `podinfo:6.14.1` into `inventory` without scanning it, and read the refusal message. Then scan it and pull again.
- Add one CVE of `6.0.0` to the system allowlist with `harbor cve-allowlist add`, and check whether `inventory` now ignores it. What decides that?
- Give a project allowlist an `expires_at` one minute in the future, wait two minutes, and pull again.
- Copy `podinfo:6.0.0` into `inventory` without `--platform` as `6.0.0-all`, and pull the tag. Then pull its `linux/amd64` image by digest.
