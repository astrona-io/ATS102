# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Replication of signed artifacts

## Scenario

Releases are built and signed in the project `staging`. The release `staging/podinfo:6.15.0` is signed with a Cosign key and carries an SBOM. Production serves from the project `prod`, which is empty. The team wants a replication rule named `staging-to-prod` that promotes artifacts from `staging` to `prod`, and it wants the first promotion done.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. The workstation pod has `cosign`, `regctl`, `curl` and `jq`. Open a shell in it:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

The signing key pair is in `/root/build`.

## Your task

1. Create a registry endpoint that points at this Harbor.
2. Create a replication rule named `staging-to-prod` that copies the repositories of `staging` into `prod`, with a manual trigger.
3. Start the rule and wait for the execution to finish.
4. Check that `prod/podinfo:6.15.0` has the same digest as the source, a valid Cosign signature and an SBOM accessory.

## Constraints

- Do not push or copy the image with `regctl` or `docker`. The copy must come from a replication execution.
- Do not sign or re-sign anything. The signature must arrive by replication.
- Do not change the project settings of `staging`.

## Done when

- A rule named `staging-to-prod` exists, is enabled and points at the project `prod`.
- `prod/podinfo:6.15.0` has the same digest as `staging/podinfo:6.15.0`.
- `cosign verify` succeeds for the production digest with the public key, and the artifact has an accessory of the type `sbom.harbor`.
