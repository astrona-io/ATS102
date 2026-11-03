# Keys, Keyless Signing And Rotation

Everything so far depends on a private key staying private. A key that is copied, leaked or forgotten is a risk that grows with time. This part covers how to keep a key, what keyless signing is and why this course does not use it, and how to replace a key without leaving the artifacts unverifiable.

## Keep keys safe

A key pair made with `cosign generate-key-pair` has two files. The public key is for everyone. The private key `cosign.key` is encrypted with the password in `COSIGN_PASSWORD`, and it is the file to protect.

| Practice | Why |
| --- | --- |
| Keep the private key in a secret store, not in the repository | A repository is copied to many places |
| Give the signing job read access to the key, and nobody else | Fewer holders mean fewer leaks |
| Keep the password apart from the key file | A stolen file alone is then not enough |
| Use a separate key for each role | The build key and the security key from the module are examples |
| Publish the public key where consumers get it from you | They verify against a key you control |

## Keyless signing

Cosign can sign without a long-lived key. In **keyless signing**, the signer proves its identity to an identity provider, such as a CI system, and a certificate authority called **Fulcio** issues a certificate that lasts a few minutes. Cosign signs with it and records the signature in a public log called **Rekor**. A verifier then checks the identity and the issuer instead of a key:

```sh
cosign verify --certificate-identity "$IDENTITY" --certificate-oidc-issuer "$ISSUER" "$IMAGE"
```

The advantage is that there is no key to steal or rotate. The cost is that signing and verifying need the public Sigstore services, or a Sigstore deployment of your own. The playground cluster has no such services, which is why every command in this module uses a key with `--use-signing-config=false --tlog-upload=false`. Know the idea for the exam and your own work, and notice that the Harbor side is the same: a signature is stored as an accessory either way.

## Rotate a key

You rotate a key on a schedule, and at once after a leak. The goal is that consumers can verify every artifact before, during and after the change. Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Make a new build key pair in a new directory, and sign the release with it. The old signature stays where it is:

```sh
mkdir -p /root/build-next && cd /root/build-next
COSIGN_PASSWORD=next-signing-password cosign generate-key-pair
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.15.0)
COSIGN_PASSWORD=next-signing-password cosign sign --yes --key /root/build-next/cosign.key \
  --use-signing-config=false --tlog-upload=false "harbor.localtest.me:8443/release/podinfo@$DIGEST"
```

Both keys now verify the release:

```sh
cosign verify --key /root/build/cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.15.0 >/dev/null && echo old-ok
cosign verify --key /root/build-next/cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.15.0 >/dev/null && echo new-ok
```

This overlap is the safe path:

1. Create the new key pair.
2. Sign new releases with the new key, and sign the releases that are still in use again with it.
3. Give consumers the new public key, and let them accept either key for a while.
4. When every consumer uses the new key, remove the old public key from them and retire the old private key.

After a leak you shorten the overlap, and consumers stop trusting the old public key at once. A signature by a leaked key proves nothing, because anyone can make one. Signatures that the old key made on artifacts you still want are then replaced by signatures from the new key, and the old signatures can be deleted from Harbor like any accessory.

## Keys in the cluster

Admission controllers and policy tools hold the public key and verify before a pod starts. They accept a list of keys, which is what makes the overlap possible. Change that list in two steps, add the new key and then remove the old one, and never replace the key in one step while old artifacts are still running.

You now know how to keep a key, what keyless signing replaces, and how to rotate with an overlap so that nothing stops verifying.

## Common pitfalls

> [!WARNING]
> - **Replacing the key in one step.** Artifacts signed only with the old key stop verifying.
> - **Keeping the old key trusted forever.** After a leak, that trust is the hole.
> - **Storing the password next to the key.** One stolen location then gives both.
> - **Running keyless commands in the private playground.** They need services the cluster does not have.
