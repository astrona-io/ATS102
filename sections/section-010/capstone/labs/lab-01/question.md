# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Vulnerability scanning

## Scenario

The Harbor project `release` holds the two current releases of `podinfo`, `6.14.1` and `6.15.0`. Yesterday someone started a scan of both, and both scans ended in an error. Nobody looked into it. The project does not scan new artifacts either, so the next release would arrive without any report at all.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Work in the workstation pod, and use `kubectl` on your machine for the cluster itself:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Find out why the scans in `release` end in an error, and fix the cause.
2. Give every artifact in `release/podinfo` a successful vulnerability report.
3. Make Harbor scan every new artifact pushed to `release` without anyone asking.

## Constraints

- Do not register another scanner, and do not change which scanner is the default.
- Do not reinstall Harbor and do not delete artifacts.

## Done when

- Harbor's health endpoint reports the `trivy` component as `healthy`, and its pod is ready.
- Every artifact in `release/podinfo` has a vulnerability report with the status `Success`.
- A new artifact pushed to `release/podinfo` gets a successful report without a manual scan. The grader pushes one to test this.
