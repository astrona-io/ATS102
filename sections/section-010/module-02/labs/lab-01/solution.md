# Solution: Report Only Fixable Vulnerabilities

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the adapter runs with the setting, and the report of `6.0.0` is complete and has only fixable findings.

## Step 1: Look at the adapter settings

On your machine, print the environment of the adapter:

```sh
kubectl -n harbor get statefulset harbor-trivy -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
```

`SCANNER_TRIVY_IGNORE_UNFIXED` is `false`. This variable decides whether a report includes vulnerabilities that no package version fixes yet.

## Step 2: Change the setting and wait for the new pod

```sh
kubectl -n harbor set env statefulset/harbor-trivy SCANNER_TRIVY_IGNORE_UNFIXED=true
kubectl -n harbor rollout status statefulset/harbor-trivy --timeout=300s
```

Kubernetes replaces the `harbor-trivy-0` pod. The new pod has an empty cache, so it downloads the Trivy database on its first scan.

## Step 3: Scan the artifact again

In the workstation shell, sign the `harbor` tool in and start the scan:

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor artifact scan start inventory/podinfo/6.0.0
```

Wait for the status `Success`. The first scan can take a few minutes because of the database download:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0?with_scan_overview=true" | jq '[.scan_overview[]?.scan_status][0]'
```

If the status is `Error`, read the scan log, as the module showed, and scan again when the adapter is ready.

## Step 4: Check the report

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq '{total: ([.[].vulnerabilities[]] | length), without_fix: ([.[].vulnerabilities[] | select((.fix_version // "") == "")] | length)}'
```

`without_fix` is `0`, and `total` is greater than `0`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set the variable and not scan again | The old report stays, and it still lists findings without a fix |
| Filter the findings with `jq` and call it done | Harbor's report is unchanged; the setting belongs on the scanner |
| Delete `6.0.0` | The task is a report for the artifact, not an empty repository |

## Common mistakes

- Reading the report before the status is `Success`.
- Starting a second scan while the first one downloads the database.
- Using `helm upgrade` for the change without the same value in the values file, which would write the old value again.
