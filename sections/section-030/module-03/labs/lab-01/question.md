# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Content trust with Notation

## Scenario

The team will sign releases with Notation instead of Cosign. The release `release/podinfo:6.15.0` is unsigned. The team wants it signed, and it wants a strict trust policy on the workstation that accepts only the team's signing certificate, so that `notation verify` passes for exactly that certificate.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. The workstation pod has the `notation` tool. Open a shell in it:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Create a test key and certificate for Notation and make it the default signing key.
2. Sign `release/podinfo:6.15.0` by its digest.
3. Import a trust policy with the verification level `strict` that trusts the trust store of your certificate.
4. Check that `notation verify` passes for the release.

## Constraints

- Sign the digest, not the tag.
- Do not push another image to `release` and do not change the project settings.
- Do not use the verification level `skip`.

## Done when

- `release/podinfo:6.15.0` has an accessory of the type `signature.notation`.
- A trust policy is imported, and `notation verify` succeeds for the digest of `release/podinfo:6.15.0`.
