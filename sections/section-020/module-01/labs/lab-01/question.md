# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** SBOM

## Scenario

The compliance team needs a Software Bill of Materials (SBOM) for every image the `podinfo` team ships through the Harbor project `inventory`. Today no artifact in the project has one. From now on, every new artifact must get its SBOM automatically, and the current release `6.15.0` needs one too.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Work in the workstation pod, which has `regctl`, the `harbor` command-line tool, `curl` and `jq`:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Turn on automatic SBOM generation for the project `inventory`.
2. Push the new release: copy `ghcr.io/stefanprodan/podinfo:6.14.1` for `linux/amd64` only into `inventory/podinfo:6.14.1`. Do not ask for its SBOM yourself.
3. Generate an SBOM for `inventory/podinfo:6.15.0`.
4. Download the SBOM of `6.14.1` and check that it is an SPDX document with packages.

## Constraints

- Push `6.14.1` **after** automatic SBOM generation is on. The grader compares the time of the push with the start of the SBOM job.
- Do not delete artifacts from `inventory/podinfo`.

## Done when

- The project `inventory` has `auto_sbom_generation` set to `true`.
- `inventory/podinfo:6.14.1` exists, and its SBOM job started within two minutes of its push.
- `6.14.1` and `6.15.0` both have an SBOM accessory, and each SBOM is an SPDX document that lists packages.
