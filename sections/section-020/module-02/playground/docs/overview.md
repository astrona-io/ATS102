# Overview: Read And Use The Content Of An SBOM (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, copies some artifacts into it, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` and the password `Harbor12345`. Its built-in Trivy adapter generates SBOMs.
- The **workstation** pod in the namespace `workstation`, with `regctl`, `cosign`, `oras`, `curl` and `jq`. It trusts Harbor's certificate.
- The project **`audit`** with two artifacts that have no SBOM yet:

  | Artifact | What it is |
  | --- | --- |
  | `audit/podinfo:6.15.0` | A release of the `podinfo` web application, `linux/amd64` only |
  | `audit/alpine:3.20` | The Alpine Linux base image, `linux/amd64` only |

- The project **`warmup`**, with one scanned artifact so that the Trivy database is already downloaded.

## Helpers

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Paste these once in each new workstation shell. `api` calls the Harbor REST API as `admin`. `sbom` downloads the SPDX document of one tag in `audit` to standard output.

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
sbom() {
  digest=$(api "$API/projects/audit/repositories/$1/artifacts/$2?with_sbom_overview=true" | jq -r '.sbom_overview.sbom_digest')
  regctl artifact get "harbor.localtest.me:8443/audit/$1@$digest"
}
```

Use it like this: `sbom alpine 3.20 | jq '.packages | length'`. Generate an SBOM first with `api -X POST "$API/projects/audit/repositories/alpine/artifacts/3.20/scan" -d '{"scan_type":"sbom"}'`.

## Practice tasks

- Generate the SBOM of both artifacts, download them, and list the top-level keys of each document.
- Count the relationships by type. Find the identifier of the package that the document `DESCRIBES`.
- List every package with its version and purl. Count the packages in each artifact and find the packages that only `podinfo` has.
- Count the declared licenses and find the packages with `NOASSERTION`.
- Scan an artifact for vulnerabilities, and join the vulnerable package names with the SBOM package names.
- List the accessories of an artifact. Regenerate the SBOM and compare the digests before and after.
- Compare the digest of the tag with `subject_artifact_digest` of the SBOM accessory.
- Create a global label, attach it to one artifact, and list the labels of both artifacts.
