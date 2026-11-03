# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Vulnerability scanning

## Scenario

The release pipeline of the team behind `podinfo` fails on every High finding in a report. For the old release `inventory/podinfo:6.0.0`, many of those findings have no fixed version, so the team cannot fix them by updating the image. The security team agrees that the report should list only findings that an update can fix, and it wants this set on the scanner, not in the pipeline.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Use two shells: one on your machine for `kubectl`, and one in the workstation pod for the API:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Make the Trivy adapter leave out vulnerabilities that have no fixed version.
2. Scan `inventory/podinfo:6.0.0` again after the change.
3. Make sure the report of `6.0.0` has the status `Success` and lists only findings that have a fixed version.

## Constraints

- Change the running adapter. Do not install Harbor again and do not delete the `harbor` namespace.
- Do not register another scanner and do not delete artifacts.
- The first scan after the adapter restarts downloads the Trivy database again. Wait for it instead of starting the scan again.

## Done when

- The StatefulSet `harbor-trivy` has the variable `SCANNER_TRIVY_IGNORE_UNFIXED` set to `true`, and its pod is ready.
- `inventory/podinfo:6.0.0` has a vulnerability report with the status `Success` that lists at least one finding.
- No finding in that report has an empty fixed version.
