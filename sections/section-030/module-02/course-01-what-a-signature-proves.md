# What A Signature Proves

A green result from `cosign verify` feels like a guarantee. It is a precise statement, and it is narrower than it feels. This part looks at what Harbor stores for a signed artifact, and then at what a check tells you and what it leaves open.

## Look at what is stored

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Sign in to the registry, and ask Cosign for the objects attached to one release:

```sh
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
cosign tree harbor.localtest.me:8443/release/podinfo:6.15.0
```

`cosign tree` lists what hangs off the artifact: signatures, attestations and SBOMs that Cosign knows how to find. Harbor's API shows the same objects as accessories of the artifact. Read them with `curl`:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/release/repositories/podinfo/artifacts/6.15.0/accessories" | jq '.[] | {type, digest, subject_artifact_digest}'
```

Each signature is its own object with its own digest, and it points at the digest of the signed artifact. The signature is not inside the image and not inside the tag. That is why a signature cannot be lost by pulling the image, and why a new image under the same tag has no signature.

## What a successful check proves

Verify the release with the build public key:

```sh
cosign verify --key /root/build/cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.15.0
```

When the command succeeds, three facts are true:

1. A signature object for this digest exists.
2. It was made by the private key that matches `/root/build/cosign.pub`.
3. The signed data was not changed after signing.

Cosign resolves the tag to a digest before it checks, and it prints the digest it verified. A check by tag is therefore a check of the digest that the tag pointed at in that moment.

## What it does not prove

A signature does not say that the image is safe, that it has no vulnerabilities, or that anybody reviewed it. It says that the holder of one key vouched for one digest. Four questions stay open:

| Question | Who answers it |
| --- | --- |
| Is the key the right key | You, by keeping the public key from a trusted source |
| Was the key stolen | Your key management, and rotation |
| What did the signer check before signing | An annotation or an attestation, in the next parts |
| Is the image free of known flaws | The scanner and the project policy |

The first row is the most important. `cosign verify --key` with a public key that you do not control proves nothing. Take the public key from your own repository or your own secret store, not from the registry that holds the image.

## Check a second tag

The release `6.14.1` is signed too. Verify it, and then compare the two digests:

```sh
cosign verify --key /root/build/cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.14.1 | jq -r '.[0].critical.image."docker-manifest-digest"'
regctl image digest harbor.localtest.me:8443/release/podinfo:6.14.1
```

The two lines are the same digest. Cosign prints one JSON object per verified signature, and the field `critical.image.docker-manifest-digest` is the digest it checked.

You now know where signatures live, what a passing check means, and what it leaves open. One of the open questions is what the signer claimed, which a signature can carry as an annotation.

## Common pitfalls

> [!WARNING]
> - **Treating a signature as a safety mark.** It proves who signed a digest, nothing more.
> - **Fetching the public key from the registry that holds the image.** An attacker who controls the registry controls the key too.
> - **Verifying a tag and pinning the tag.** Pin the digest that the check printed.
> - **Expecting a signature to move with a re-pushed tag.** A new digest has no signature.
