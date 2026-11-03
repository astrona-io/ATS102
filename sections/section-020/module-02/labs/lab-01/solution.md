# Solution: Label Artifacts By Package From Their SBOM

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: both SBOMs exist, the label exists, and the label sits on exactly the artifacts whose SBOM lists `curl`.

## Step 1: Define the helpers

In the workstation shell:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
```

## Step 2: Generate both SBOMs

```sh
api -X POST "$API/projects/audit/repositories/podinfo/artifacts/6.15.0/scan" -d '{"scan_type":"sbom"}'
api -X POST "$API/projects/audit/repositories/alpine/artifacts/3.20/scan" -d '{"scan_type":"sbom"}'
```

Wait until both read `Success`:

```sh
for pair in podinfo:6.15.0 alpine:3.20; do
  api "$API/projects/audit/repositories/${pair%%:*}/artifacts/${pair##*:}?with_sbom_overview=true" | jq -r '.sbom_overview.scan_status'
done
```

## Step 3: Read each SBOM

For each artifact, download the SBOM by its digest and count the packages named exactly `curl`:

```sh
for pair in podinfo:6.15.0 alpine:3.20; do
  repo=${pair%%:*}; tag=${pair##*:}
  digest=$(api "$API/projects/audit/repositories/$repo/artifacts/$tag?with_sbom_overview=true" | jq -r '.sbom_overview.sbom_digest')
  echo "$repo:$tag $(regctl artifact get harbor.localtest.me:8443/audit/$repo@$digest | jq '[.packages[] | select(.name == "curl")] | length')"
done
```

A count above `0` means the SBOM lists `curl`. Note which artifacts have it. Do not assume both or neither.

## Step 4: Create the label

```sh
api -X POST "$API/labels" -d '{"name":"uses-curl","scope":"g","color":"#1E88E5","description":"The SBOM lists curl"}'
LABEL_ID=$(api "$API/labels?name=uses-curl&scope=g" | jq -r '.[0].id')
```

## Step 5: Attach the label to the matching artifacts only

For each artifact with a count above `0`, attach the label. This example is for `podinfo:6.15.0`; change the repository and tag to match your result:

```sh
api -X POST "$API/projects/audit/repositories/podinfo/artifacts/6.15.0/labels" -d "{\"id\":$LABEL_ID}"
```

Check the result for both artifacts:

```sh
for pair in podinfo:6.15.0 alpine:3.20; do
  api "$API/projects/audit/repositories/${pair%%:*}/artifacts/${pair##*:}" | jq -c '{ref: "'$pair'", labels: [.labels[]?.name]}'
done
```

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Label both artifacts | The grader fails the artifact whose SBOM does not list `curl` |
| Decide from the vulnerability report | The report lists only packages with known flaws, so it can miss a package |
| Match with a substring such as `contains("curl")` | Packages such as `libcurl` match too, and the label lands on the wrong artifact |

## Common mistakes

- Reading the SBOM before its status is `Success`, which gives an empty digest.
- Creating the label as a project label instead of a global label.
- Attaching the label to the artifact by a different tag than the one in the project.
