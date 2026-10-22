# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Deployment security

## Scenario

The security team has decided that no artifact with a High or Critical vulnerability may be pulled from the Harbor projects `inventory` and `legacy`. There is one reviewed exception: the old `podinfo:6.0.0` in the project `legacy` must keep working for the next two weeks while its replacement is built. The same image in `inventory` gets no exception.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Every artifact is already scanned. Work in the workstation pod:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Make both `inventory` and `legacy` refuse artifacts with vulnerabilities of severity High or above.
2. Give `legacy` its own CVE allowlist that lets `legacy/podinfo:6.0.0` be pulled. List only the High and Critical CVEs of that artifact.
3. Make that allowlist expire between now and 30 days from now.

## Constraints

- The severity threshold of both projects must be `high`. Do not turn the policy off and do not raise the threshold to `critical`.
- Do not add anything to the system CVE allowlist; it must stay empty.
- Do not delete or replace any artifact.

## Done when

- Both projects have vulnerability prevention on at severity `high`.
- A pull of `inventory/podinfo:6.0.0` is refused with `412`. A pull of `inventory/podinfo:6.15.0` is refused or allowed according to its own report.
- `legacy` uses its own allowlist (not the system one); the list is not empty, names only High or Critical CVEs of `legacy/podinfo:6.0.0`, and expires within 30 days. A pull of `legacy/podinfo:6.0.0` returns `200`.
- The system CVE allowlist is empty.
