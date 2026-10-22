# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Content trust

## Scenario

The Harbor project `release` holds the current release `podinfo:6.15.0` and the release candidate `podinfo:6.14.1-rc`. Neither is signed, and the project serves both to anyone. From today, only signed releases may leave the project, and the candidate must never be pulled by mistake.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Work in the workstation pod, which has `cosign`, `regctl`, the `harbor` command-line tool, `curl` and `jq`:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Create a Cosign key pair in the folder `/root` of the workstation, so that the files are `/root/cosign.key` and `/root/cosign.pub`. Choose your own password.
2. Sign `release/podinfo:6.15.0` by its digest with that key. Do not upload anything to the public transparency log.
3. Make the project `release` refuse every artifact that has no Cosign signature.

## Constraints

- Sign **only** `6.15.0`. The candidate `6.14.1-rc` must stay unsigned, and it must stay in the project.
- Keep `/root/cosign.pub` in place; the grader verifies with it.

## Done when

- Cosign signature enforcement is on for `release`.
- `release/podinfo:6.15.0` has a Cosign signature accessory, `cosign verify` succeeds with `/root/cosign.pub`, and its manifest pulls with status `200`.
- `release/podinfo:6.14.1-rc` has no Cosign signature, and a pull of its manifest is refused with status `412`.
