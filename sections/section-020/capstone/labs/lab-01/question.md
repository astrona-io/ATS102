# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** SBOM

## Scenario

Before the `podinfo` team may ship from the Harbor project `release`, every artifact in it must carry two things: a successful vulnerability report and a Software Bill of Materials (SBOM). Today only `6.15.0` has been scanned, nothing has an SBOM, and the project does neither on its own.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Work in the workstation pod:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Give every artifact in `release/podinfo` a successful vulnerability report.
2. Give every artifact in `release/podinfo` an SBOM.
3. Make Harbor do both on its own for every new artifact pushed to `release`.

## Constraints

- Do not delete artifacts and do not register another scanner.

## Done when

- Every artifact in `release/podinfo` has a vulnerability report with the status `Success`.
- Every artifact in `release/podinfo` has an SBOM with the status `Success`.
- A new artifact pushed to `release/podinfo` gets both without a manual request. The grader pushes one to test this.
