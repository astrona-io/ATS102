# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Vulnerability scanning

## Scenario

The team behind `podinfo` pushes a new release every week into the Harbor project `inventory`. Nobody scans anything by hand, so today not one artifact in the project has a vulnerability report. The security team wants every artifact scanned when it arrives, and every artifact scanned again every day, because the vulnerability database changes.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Work in the workstation pod, which has the `harbor` command-line tool, `regctl`, `curl` and `jq`:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Turn on scan on push for the project `inventory`.
2. Make Harbor scan all artifacts every day.
3. Push the new release: copy `ghcr.io/stefanprodan/podinfo:6.14.1` for `linux/amd64` only into `inventory/podinfo:6.14.1`. Do not start a scan of it yourself.
4. Make sure every artifact in `inventory/podinfo` has a successful vulnerability report.

## Constraints

- Push `6.14.1` **after** scan on push is on, and let Harbor scan it on its own. The grader compares the time of the push with the start of the scan.
- Do not delete artifacts from `inventory/podinfo`.
- Do not register another scanner.

## Done when

- The project `inventory` has scan on push turned on.
- The scan-all schedule is `Daily`.
- `inventory/podinfo:6.14.1` exists, and its scan started within two minutes of its push.
- Every artifact in `inventory/podinfo` has a vulnerability report with the status `Success`.
