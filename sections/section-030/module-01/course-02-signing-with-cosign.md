# Signing And Verifying With Cosign

A signature is only as good as the care around it: the right key, the right digest, and a check by the people who pull. This part does all three with Cosign. You create a key pair, sign the release `podinfo:6.15.0` by its digest without the public transparency log, find the signature in Harbor, and verify it with the public key.

## Create a key pair

Cosign signs with a **key pair**: `cosign.key`, the private key, which signs, and `cosign.pub`, the public key, which verifies. Cosign encrypts the private key with a password, which it reads from the variable `COSIGN_PASSWORD` or asks for.

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, go to `/root` and create the key pair. The password here is a lab-only value:

```sh
cd /root
export COSIGN_PASSWORD='lab-signing-password'
cosign generate-key-pair
```

Cosign writes `cosign.key` and `cosign.pub` to the current folder and says so. The private key never needs to leave this pod. In a real team, it lives in a key management service or a CI secret, and the public key is published to everyone who pulls.

## Sign the release by its digest

Cosign pushes the signature to Harbor, so it needs to sign in, like any registry client:

```sh
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
```

A signature should name the digest, not the tag, so that it is clear what was signed. Find the digest of the release with `regctl`:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.15.0)
echo "$DIGEST"
```

The output is one line starting with `sha256:`. Now sign that digest. `--key` names the private key, `--tlog-upload=false` keeps the signature out of the public transparency log, and `--yes` skips the confirmation prompt:

```sh
cosign sign --yes --key cosign.key --tlog-upload=false "harbor.localtest.me:8443/release/podinfo@$DIGEST"
```

Cosign reads the password from `COSIGN_PASSWORD`, signs the digest, and pushes the signature to the same repository. Cosign 3 stores it as an OCI 1.1 artifact that refers to its subject, in the Sigstore bundle format.

## Find the signature in Harbor

Harbor recognised the new artifact as a Cosign signature and linked it to its subject. Define the API helper and list the accessories again:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/release/repositories/podinfo/artifacts/6.15.0/accessories" | jq '.[] | {type, digest, subject_artifact_digest}'
```

There is one accessory with the type `signature.cosign`. Its `subject_artifact_digest` is the digest you signed. The release candidate `6.14.1-rc` still has no accessories, because you signed only the release.

## Verify the signature

Verification is what the people who pull should do: check the artifact against the public key before they run it. `cosign verify` finds the signatures of the artifact in the registry and checks each one with the key:

```sh
cosign verify --key cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.15.0
```

Cosign reports that the signature was verified with the given key, and prints a JSON description of the signed claims, including the digest. `--insecure-ignore-tlog=true` tells Cosign not to look for a transparency log entry, because you signed without one.

Now try the same with the release candidate:

```sh
cosign verify --key cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.14.1-rc
```

Cosign reports that it found no signatures, and exits with an error. That is the result you want: the candidate was never signed.

You can now create a key pair, sign an artifact by its digest without the public log, find the signature accessory in Harbor, and verify it. The open question is who runs `cosign verify`. People forget; a registry that refuses unsigned artifacts does not.

## Common pitfalls

> [!WARNING]
> - **Signing by tag.** Cosign resolves it, but the record should show the digest you meant. Sign `repository@sha256:...`.
> - **Forgetting `cosign login`.** Cosign pushes the signature to Harbor and needs push rights to the project.
> - **Verifying without `--insecure-ignore-tlog=true` after signing with `--tlog-upload=false`.** Cosign then looks for a log entry that does not exist and fails.
> - **Losing the password or the private key.** Nobody can sign with the key pair again; create a new one and sign again.
