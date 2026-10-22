# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Deployment security

## Scenario

The Harbor project `inventory` is supposed to refuse artifacts with High or Critical vulnerabilities. Yet the old `podinfo:6.0.0`, whose report lists Critical findings, pulls without any problem. During an incident last month, someone made a quick exception, and nobody cleaned it up.

Other teams' projects rely on the same quick exception for one more week, so it cannot simply be deleted.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Every artifact is already scanned. Work in the workstation pod:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Find every reason why `inventory/podinfo:6.0.0` can be pulled.
2. Make `inventory` refuse artifacts with vulnerabilities of severity High or above, using its own allowlist, which must be empty.
3. Keep the entries of the system CVE allowlist, but make the system allowlist expire within 7 days.

## Constraints

- Do not delete or replace any artifact.
- Do not remove entries from the system CVE allowlist.

## Done when

- `inventory` has vulnerability prevention on at severity `high`, does not reuse the system allowlist, and its own allowlist is empty.
- The system CVE allowlist still has its entries and expires within the next 7 days.
- A pull of `inventory/podinfo:6.0.0` is refused with `412`. A pull of `inventory/podinfo:6.15.0` is refused or allowed according to its own report.
