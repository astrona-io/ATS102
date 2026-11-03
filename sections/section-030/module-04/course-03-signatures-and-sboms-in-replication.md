# Signatures And SBOMs In Replication

Copying an image is not enough for a release. If the signature and the SBOM stay behind, the production copy has no proof of origin and no inventory. Harbor replicates accessories together with the artifact. This part starts the rule, waits, and checks the digest and the accessories. A graded lab follows it.

## Look at the source

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Read the digest and the accessories of the source artifact:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/staging/repositories/podinfo/artifacts/6.15.0/accessories" | jq '.[] | .type'
regctl image digest harbor.localtest.me:8443/staging/podinfo:6.15.0
```

You see a `signature.cosign` accessory and an `sbom.harbor` accessory, and one digest. Write the digest down.

## Start the execution

Find the id of the rule, start an execution, and look at it:

```sh
POL=$(api "$API/replication/policies" | jq '.[] | select(.name=="staging-to-prod") | .id')
api -X POST "$API/replication/executions" -d '{"policy_id": '"$POL"'}'
api "$API/replication/executions?policy_id=$POL" | jq '.[0] | {id, status, total, succeed, failed, in_progress}'
```

The execution moves from `InProgress` to `Succeed` or `Failed`. Run the last call again until it settles. A successful execution of this size takes a few seconds.

## Prove the artifact arrived whole

Compare the digests. They must be equal:

```sh
regctl image digest harbor.localtest.me:8443/staging/podinfo:6.15.0
regctl image digest harbor.localtest.me:8443/prod/podinfo:6.15.0
```

The same digest means the same manifest and the same layers. That is why a signature made in staging can be valid in production: a signature belongs to a digest, and the digest did not change.

## Prove the accessories arrived

List the accessories in production, and verify the signature there with the public key:

```sh
api "$API/projects/prod/repositories/podinfo/artifacts/6.15.0/accessories" | jq '.[] | .type'
DIGEST=$(regctl image digest harbor.localtest.me:8443/prod/podinfo:6.15.0)
cosign verify --key /root/build/cosign.pub harbor.localtest.me:8443/prod/podinfo@$DIGEST
```

A good copy shows both accessory types and a verification that succeeds. If the artifact is there and the accessories are not, the signature was not replicated, and production would pass any check that does not require a signature. Always check the accessories and never assume them.

## Signing in the middle

Replication does not sign. If your policy says that production artifacts need a signature from the production key, sign after the copy, not before. Many teams keep two keys: a build key that signs in staging and a release key that signs in production. The copy proves the artifact is unchanged, and the second signature proves that the release process approved it.

You can now run a rule and prove the result. The graded lab asks you to do it from a fresh start.

## Common pitfalls

> [!WARNING]
> - **Checking only that the tag exists in production.** Compare the digest, and check the accessories.
> - **Treating `Succeed` as proof.** An execution with a filter that matched nothing also succeeds.
> - **Assuming the SBOM arrived because the signature did.** List the accessory types.
> - **Verifying with the private key.** Verification uses only the public key.

## Your mission: Replicate A Signed Release To Production

You can now create an endpoint, write a rule, run it and check the result. The graded lab gives you `staging/podinfo:6.15.0`, signed and with an SBOM, and an empty `prod` project. It asks you to set up replication so that the same artifact, with its signature and SBOM, ends up in `prod`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-030-04
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-030/module-04/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-04/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-030-04
astrona start ats-102-playground-030-04
```
