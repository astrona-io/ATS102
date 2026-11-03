# Solution: Sign A Release With Notation And Verify It

Work the task yourself first. Running `astrona submit -c sections/section-030/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the release has a Notation signature accessory, and `notation verify` passes.

## Step 1: Create the certificate

In the workstation shell:

```sh
notation cert generate-test --default release-signer
notation key list
```

The certificate goes into a trust store of type `ca` named `release-signer`.

## Step 2: Sign the digest

```sh
notation login -u admin -p Harbor12345 harbor.localtest.me:8443
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.15.0)
notation sign harbor.localtest.me:8443/release/podinfo@$DIGEST
notation ls harbor.localtest.me:8443/release/podinfo@$DIGEST
```

`notation ls` lists one signature.

## Step 3: Import a strict trust policy

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
notation policy import --force /tmp/policy.json
notation policy show
```

## Step 4: Verify

```sh
notation verify harbor.localtest.me:8443/release/podinfo@$DIGEST
```

The command succeeds. If it fails, check that the trust store name in the policy matches the name you gave `generate-test`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign with Cosign | The grader looks for the type `signature.notation` |
| Set the level to `skip` | There is no verification, and the constraint forbids it |
| Sign the tag and not the digest | Notation warns, and the tag can move before the signature is made |

## Common mistakes

- Forgetting `notation login` before signing.
- Naming a trust store in the policy that `generate-test` did not create.
- Running the commands as a different user than the one the grader uses, so the configuration folder differs.
