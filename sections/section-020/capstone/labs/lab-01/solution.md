# Solution: Ship A Release With A Report And An SBOM

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: every artifact has a successful scan, every artifact has an SBOM, and a new push gets both on its own.

## Step 1: See what each artifact has

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, define the helper and print, for each tag, the scan status and the SBOM status:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
for tag in 6.14.1 6.15.0; do
  printf '%s ' "$tag"
  api "$API/projects/release/repositories/podinfo/artifacts/$tag?with_scan_overview=true&with_sbom_overview=true" \
    | jq -c '{scan: ([.scan_overview[]?.scan_status][0] // "None"), sbom: (.sbom_overview.scan_status // "None")}'
done
```

`6.15.0` has a scan and no SBOM; `6.14.1` has neither.

## Step 2: Turn on both settings

Both are project metadata keys. Set them in one request:

```sh
api -X PUT "$API/projects/release" -d '{"metadata":{"auto_scan":"true","auto_sbom_generation":"true"}}'
api "$API/projects/release" | jq '.metadata | {auto_scan, auto_sbom_generation}'
```

Both read `"true"`.

## Step 3: Fill in what is missing

The settings act only on new pushes. Ask for the missing scan and the two missing SBOMs:

```sh
api -X POST "$API/projects/release/repositories/podinfo/artifacts/6.14.1/scan"
for tag in 6.14.1 6.15.0; do
  api -X POST "$API/projects/release/repositories/podinfo/artifacts/$tag/scan" -d '{"scan_type":"sbom"}'
done
```

Run the loop from step 1 again until every value reads `Success`.

## Step 4: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

The grader copies a new tag, `grader-push`, into `release/podinfo` and waits for both a scan and an SBOM that nobody asked for.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Turn on both settings and stop | The two existing artifacts never get what they are missing |
| Fill in by hand and leave the settings off | The next release arrives with nothing |
| Rescan `6.15.0` too | Harmless, but it does not create the SBOM |

## Common mistakes

- Sending one `scan` request and expecting both a report and an SBOM. They are two scan types and two requests.
- Setting only one of the two metadata keys.
