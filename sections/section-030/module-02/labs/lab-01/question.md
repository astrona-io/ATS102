# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Signing and verification

## Scenario

The build pipeline signs every release of `podinfo` with the build key. The security team must now approve releases, and the approval has to be visible in the registry and checkable by anyone who pulls. The decision is a second signature, made with the security key, that carries the claim `approved-by=security`. The build signature must stay.

The project `release` holds `release/podinfo:6.14.1` and `release/podinfo:6.15.0`. Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. The build key pair is in `/root/build`, and the unused security key pair is in `/root/security` in the workstation pod. The key passwords are `build-signing-password` and `security-signing-password`. Use a shell in the workstation:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Sign both releases with the security key, by digest.
2. Add the annotation `approved-by=security` to each of those signatures.
3. Check that each release verifies with the security key and the annotation, and still verifies with the build key.

## Constraints

- Do not move, replace or delete the key files in `/root/build` and `/root/security`.
- Do not delete the existing signatures and do not push new images.
- Do not sign with the build key. The approval must come from the security key.
- Private environment: sign without the public transparency log.

## Done when

- `cosign verify` with `/root/security/cosign.pub` and `-a approved-by=security` succeeds for both `release/podinfo:6.14.1` and `release/podinfo:6.15.0`.
- `cosign verify` with `/root/build/cosign.pub` still succeeds for both.
