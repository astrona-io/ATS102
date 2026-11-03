# Trust Policies And Verification

Run `notation verify` before a policy exists and it fails. That is on purpose. Notation does not guess whom to trust. This part writes a trust policy, shows what each part of it does, and verifies the release. A graded lab follows it.

## The parts of a trust policy

A trust policy is a JSON file. Each entry in `trustPolicies` has these fields:

| Field | What it does |
| --- | --- |
| `name` | A name for the entry, used in messages |
| `registryScopes` | The repositories the entry covers. `*` means all of them |
| `signatureVerification.level` | How strict the check is |
| `trustStores` | The trust stores to check certificates against, written as `type:name` |
| `trustedIdentities` | Which certificate subjects are accepted. `*` means any subject in the trust store |

The **verification level** has four values:

| Level | Meaning |
| --- | --- |
| `strict` | All checks must pass, including expiry and revocation |
| `permissive` | Expiry and revocation problems are logged, not enforced |
| `audit` | Only the integrity and authenticity checks are enforced, other failures are logged |
| `skip` | No verification. Use it only for repositories that you deliberately do not check |

## Import a policy

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

If you have not signed the release in this shell's session yet, create the certificate and sign it as in the earlier steps. Then write the policy, import it, and read it back:

```sh
cat > /tmp/policy.json <<'POLICY'
{
  "version": "1.0",
  "trustPolicies": [
    {
      "name": "release",
      "registryScopes": ["*"],
      "signatureVerification": { "level": "strict" },
      "trustStores": ["ca:release-signer"],
      "trustedIdentities": ["*"]
    }
  ]
}
POLICY
notation policy import /tmp/policy.json
notation policy show
```

The store `ca:release-signer` is the one that `generate-test` filled. If a policy is already imported, add `--force` to replace it.

## Verify

```sh
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.15.0)
notation verify harbor.localtest.me:8443/release/podinfo@$DIGEST
```

The command succeeds when a signature exists, its certificate chains to a certificate in the trust store, and the policy's checks pass. Change the policy to point at a store that does not hold the certificate, import it again, and verify once more. The check now fails, even though the signature is the same. That is the proof that the policy, not the signature alone, decides.

## Scope the policy

A real policy has one entry per group of repositories. A policy can trust one certificate for `harbor.example.com/release/*` and another for `harbor.example.com/test/*`, and skip checking for a scratch project. Notation applies the first entry whose scope matches the repository, and a repository that matches no entry fails verification.

You can now write a trust policy, import it, and verify with it. The graded lab uses all three steps on a fresh cluster.

## Common pitfalls

> [!WARNING]
> - **Using `trustedIdentities: ["*"]` in production.** Any certificate in the trust store is then accepted. Name the subjects.
> - **Putting a verification level of `skip` in a broad scope.** It switches the checks off for everything the scope covers.
> - **Verifying by tag.** Verify the digest you plan to deploy.
> - **Keeping a policy that no longer matches the trust store.** Verification then fails for every artifact.

## Your mission: Sign A Release With Notation And Verify It

You can now create a certificate, sign by digest, write a policy and verify. The graded lab gives you the project `release` with an unsigned `podinfo:6.15.0` and the `notation` tool in the workstation. It asks you to sign the release with Notation and to leave a strict trust policy in place under which `notation verify` passes.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-030-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-030/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-030-03
astrona start ats-102-playground-030-03
```
