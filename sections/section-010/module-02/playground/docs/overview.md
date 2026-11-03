# Overview: Configure Trivy And Read Findings In Depth (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies some artifacts into it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`. Its built-in Trivy adapter, the `trivy` component, is the default scanner.
- The **workstation** pod in the namespace `workstation`, with the `harbor` command-line tool, `regctl`, `cosign`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`inventory`** with two artifacts that nobody has scanned:

  | Artifact | What it is |
  | --- | --- |
  | `inventory/podinfo:6.0.0` | An old release of the `podinfo` web application, `linux/amd64` only, with many known vulnerabilities |
  | `inventory/podinfo:6.15.0` | A recent release, `linux/amd64` only |

- The project **`warmup`**, with one scanned artifact. The playground scanned it so that the Trivy database is already downloaded.

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell. `api` calls the Harbor REST API as `admin`. `findings` prints the severity, package, installed version and fixed version of every finding of one tag in `inventory/podinfo`.

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
findings() {
  api "$API/projects/inventory/repositories/podinfo/artifacts/$1/additions/vulnerabilities" \
    | jq -r '.[].vulnerabilities[] | [.severity, .id, .package, .version, (.fix_version // "-")] | @tsv'
}
```

Use it like this: `findings 6.0.0 | sort | head`. Sign the `harbor` tool in once per workstation pod with `harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin`.

## Practice tasks

- List the scanner registrations, read the metadata of the default one, and compare its `url` with the Service shown by `kubectl -n harbor get svc harbor-trivy`.
- Register the adapter a second time under another name, assign it to `inventory`, scan `6.15.0`, and set the project back to the default scanner.
- Print the environment of the `harbor-trivy` StatefulSet. Set `SCANNER_TRIVY_SEVERITY=HIGH,CRITICAL` with `kubectl set env`, scan `6.0.0` again, and count the severities in the new report.
- Scan `6.0.0`, then count the findings per package and find the package with the most findings.
- Scan `6.15.0`, stop the scan at once, and compare the `scan_status` with a scan you let finish. Then read the log of a finished scan.
- Scale the adapter down with `kubectl -n harbor scale statefulset harbor-trivy --replicas=0`, start a scan, and read the status and the log. Scale it back to `1`.
