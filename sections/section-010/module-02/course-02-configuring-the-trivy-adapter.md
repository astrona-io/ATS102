# Configuring The Trivy Adapter

The Trivy adapter decides what a report contains. It can hide findings that have no fix, hide low severities, skip the library packages, work without internet access, and wait longer for a big image. None of these settings live in Harbor's web portal. They live in the environment of the `trivy` pod. This part shows the settings, changes one on a running Harbor, and watches the report change.

## Where the settings live

The adapter reads its settings from environment variables whose names start with `SCANNER_TRIVY_`. When you install Harbor with the Helm chart, the chart fills them from the `trivy` block of the values file. The table lists the ones you meet most often. The variable's name is on the left and the chart value that sets it is next to it.

| Variable | Chart value | What it does |
| --- | --- | --- |
| `SCANNER_TRIVY_IGNORE_UNFIXED` | `trivy.ignoreUnfixed` | When `true`, the report leaves out vulnerabilities that have no fixed version |
| `SCANNER_TRIVY_SEVERITY` | `trivy.severity` | The severities to report, for example `HIGH,CRITICAL` |
| `SCANNER_TRIVY_VULN_TYPE` | `trivy.vulnType` | `os`, `library`, or both: operating system packages and language packages |
| `SCANNER_TRIVY_SKIP_UPDATE` | `trivy.skipUpdate` | When `true`, the adapter never downloads the vulnerability database |
| `SCANNER_TRIVY_OFFLINE_SCAN` | `trivy.offlineScan` | When `true`, Trivy makes no network calls while it resolves packages |
| `SCANNER_TRIVY_GITHUB_TOKEN` | `trivy.gitHubToken` | A GitHub token that raises the rate limit for the database download |
| `SCANNER_TRIVY_TIMEOUT` | `trivy.timeout` | How long one scan may run before it fails |
| `SCANNER_TRIVY_INSECURE` | `trivy.insecure` | When `true`, Trivy accepts an untrusted registry certificate |

A Harbor that has no internet access sets `skipUpdate` to `true` and loads the database by other means. In that case the report is as old as the database that was loaded, and the adapter does not warn about it.

## Read the current settings

Run the commands in this part on your machine, not in the workstation, because they use `kubectl` against the cluster.

<!-- astrona:playground:renew -->

```sh
kubectl -n harbor get statefulset harbor-trivy -o jsonpath='{range .spec.template.spec.containers[0].env[*]}{.name}={.value}{"\n"}{end}'
```

Every environment variable of the adapter is printed on its own line. The ones with an empty value after the `=` come from a Secret. Find `SCANNER_TRIVY_IGNORE_UNFIXED`: it is `false`, the chart's default.

## Scan before the change

Take the old release `6.0.0` as the example. Scan it, in the workstation shell, and count the findings that have no fixed version. Sign the `harbor` tool in once and start the scan:

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor artifact scan start inventory/podinfo/6.0.0
```

Define the helpers, wait until the scan has the status `Success`, and then count:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0?with_scan_overview=true" | jq '[.scan_overview[]?.scan_status][0]'
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq '[.[].vulnerabilities[] | select((.fix_version // "") == "")] | length'
```

The second command prints the number of findings whose `fix_version` is empty. For this old image, the number is not zero. These are flaws that the distribution has not fixed, so an update of the image would not remove them. A team that has to act on every report finds such lines frustrating, because it cannot do anything about them.

## Change the setting

Set the variable on the StatefulSet. Kubernetes starts a new `trivy` pod with the new environment and removes the old one. Run this on your machine:

```sh
kubectl -n harbor set env statefulset/harbor-trivy SCANNER_TRIVY_IGNORE_UNFIXED=true
kubectl -n harbor rollout status statefulset/harbor-trivy --timeout=300s
```

The second command waits until the new pod is ready. The Helm chart keeps the Trivy database in the pod only, so the new pod downloads the database again on its first scan. That first scan takes longer, and scanning again at once while one runs is refused.

## Scan after the change

Scan `6.0.0` again and count again, in the workstation shell:

```sh
harbor artifact scan start inventory/podinfo/6.0.0
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0?with_scan_overview=true" | jq '[.scan_overview[]?.scan_status][0]'
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq '[.[].vulnerabilities[] | select((.fix_version // "") == "")] | length'
```

Wait for `Success` before you count. The number is now `0`, and the total number of findings is lower than before. The new report replaced the old one, and it only lists what an update would fix.

Be careful with what this means. The setting does not make the image safer. It changes what the report shows. A setting that hides findings suits a team whose pipeline fails on every High finding, because the pipeline then fails only for things the team can fix. It does not suit an audit that must see every known flaw.

One more fact matters for operations. A `helm upgrade` writes the environment from the values file again, so a change made with `kubectl set env` is lost at the next upgrade unless the same value is in the values file as `trivy.ignoreUnfixed: true`.

You can now say where the Trivy adapter reads its settings, change one on a running Harbor, and see the effect in a report. The open question is how to read the findings that remain: what their severities and scores mean.

## Common pitfalls

> [!WARNING]
> - **Changing the setting and reading the old report.** A report changes only after a new scan.
> - **Treating a shorter report as a safer image.** The image is the same. Only the report changed.
> - **Setting the variable with `kubectl set env` and then running `helm upgrade`.** The upgrade writes the chart's value again.
> - **Scanning at once after the pod restarts.** The new pod downloads the database first, so the scan takes longer.

## Your mission: Report Only Fixable Vulnerabilities

You can now change the Trivy adapter setting that hides findings without a fix. The graded lab gives you a Harbor whose reports list every finding. It asks you to make the adapter ignore unfixed vulnerabilities, scan `6.0.0` again, and end with a successful report that has only findings with a fixed version.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-010-02
astrona start ats-102-playground-010-02
```
