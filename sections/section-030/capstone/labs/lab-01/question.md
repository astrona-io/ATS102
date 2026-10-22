# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Content trust

## Scenario

The Harbor project `release` holds the releases `podinfo:6.14.1` and `podinfo:6.15.0`, and a `debug` build that must never be pulled. A former colleague signed both releases with a personal key, kept in `/root/old-key` in the workstation. The team does not trust that key. The team's own key pair is in `/root/team`, and its password is `team-signing-password`. On top of that, the project accepts unsigned artifacts.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. Work in the workstation pod:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Find out which releases verify with the team's public key `/root/team/cosign.pub`.
2. Sign `release/podinfo:6.14.1` and `release/podinfo:6.15.0` with the team key, by digest and without the public transparency log.
3. Make the project `release` refuse every artifact without a Cosign signature.

## Constraints

- Do not move or replace the team key pair in `/root/team`.
- `release/podinfo:debug` must stay in the project and stay unsigned.
- Do not delete or move tags.

## Done when

- Cosign signature enforcement is on for `release`.
- `6.14.1` and `6.15.0` both verify with `/root/team/cosign.pub`, and both pull with status `200`.
- `release/podinfo:debug` has no Cosign signature, and a pull of it is refused with status `412`.
