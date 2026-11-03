# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** SBOM generation and content

## Scenario

A new advisory names the package `curl`. The security team wants to know which artifacts in the project `audit` contain it, and it wants the answer stored in Harbor so that the next engineer does not search again. The project holds `audit/podinfo:6.15.0` and `audit/alpine:3.20`. Neither has an SBOM yet. Vulnerability reports are no help: the advisory is new, so no report lists it.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Use a shell in the workstation pod:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Generate an SBOM for both artifacts.
2. Read each SBOM and find out whether it lists a package named `curl`.
3. Create a global label named `uses-curl`.
4. Attach the label to every artifact whose SBOM lists `curl`, and to no other artifact.

## Constraints

- Decide from the SBOM content, not from the artifact name or from memory.
- Do not delete or push artifacts, and do not change the project settings.
- Match the package name exactly. A package such as `libcurl4` is not `curl`.

## Done when

- Both artifacts have an SBOM with the status `Success`.
- A global label named `uses-curl` exists.
- Each artifact carries the label if and only if its SBOM lists a package named `curl`.
