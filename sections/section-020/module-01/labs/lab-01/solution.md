# Solution: Generate An SBOM For Every Pushed Artifact

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: automatic SBOM generation is on, `6.14.1` got its SBOM on push, and both SBOMs are SPDX documents with packages.

## Step 1: Look at the starting state

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, define the API helper and read the project's metadata:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory" | jq .metadata
```

`auto_sbom_generation` is `"false"`.

## Step 2: Turn on automatic SBOM generation

The `harbor` command-line tool v0.0.27 has no flag for this setting, so use the REST API:

```sh
api -X PUT "$API/projects/inventory" -d '{"metadata":{"auto_sbom_generation":"true"}}'
api "$API/projects/inventory" | jq -r .metadata.auto_sbom_generation
```

It now reads `true`.

## Step 3: Push the new release

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.1 harbor.localtest.me:8443/inventory/podinfo:6.14.1
```

Do not ask for an SBOM. Check that Harbor started one on its own:

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.14.1?with_sbom_overview=true" \
  | jq '{push_time, sbom: (.sbom_overview | {scan_status, start_time, sbom_digest})}'
```

The SBOM job started seconds after `push_time`. Wait until `scan_status` reads `Success`.

## Step 4: Generate an SBOM for 6.15.0

`6.15.0` was pushed before the setting was on, so it has no SBOM. Ask for one:

```sh
api -X POST "$API/projects/inventory/repositories/podinfo/artifacts/6.15.0/scan" -d '{"scan_type":"sbom"}'
```

Follow its `sbom_overview` with the same command as in step 3, with `6.15.0`, until it reads `Success`.

## Step 5: Download and check the SBOM of 6.14.1

```sh
SBOM_DIGEST=$(api "$API/projects/inventory/repositories/podinfo/artifacts/6.14.1?with_sbom_overview=true" | jq -r '.sbom_overview.sbom_digest')
regctl artifact get -m application/spdx+json "harbor.localtest.me:8443/inventory/podinfo@$SBOM_DIGEST" > podinfo-6.14.1.spdx.json
jq '{spdxVersion, packages: (.packages | length)}' podinfo-6.14.1.spdx.json
```

`spdxVersion` starts with `SPDX-`, and the package count is well above zero.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Push `6.14.1` first, then turn the setting on | `6.14.1` gets no SBOM on push; the grader sees an SBOM that started long after the push |
| Ask for the SBOM of `6.14.1` by hand | It gets one, but nothing proves the project would do it for the next release |
| Send the `scan` request without the body | That starts a vulnerability scan, not an SBOM |

## Common mistakes

- Downloading by the image digest instead of `sbom_digest`. The image manifest has no SPDX layer.
- Copying without `--platform`. The artifact becomes an image index, and the SBOMs belong to the platform images inside it.
- Reading the overview before it reads `Success`.
