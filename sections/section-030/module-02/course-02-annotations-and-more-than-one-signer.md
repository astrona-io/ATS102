# Annotations And More Than One Signer

A build system signs every image it produces. That says the image came from the build, and nothing about whether the security team accepted it. A second signature from a different key, with a claim such as `approved-by=security`, records that decision where every reader of the registry can check it. This part adds both and ends with a graded lab.

## Annotations

An **annotation** is a key and value pair stored inside the signed payload. Because the signature covers the payload, an annotation cannot be changed or added later without breaking the signature. You add one with `-a key=value` when you sign. Repeat the flag for more annotations.

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Sign the release `6.14.1` with the build key again and a build annotation:

```sh
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.14.1)
COSIGN_PASSWORD=build-signing-password cosign sign --yes --key /root/build/cosign.key \
  --use-signing-config=false --tlog-upload=false -a built-by=ci -a pipeline=release \
  "harbor.localtest.me:8443/release/podinfo@$DIGEST"
```

Signing by digest, as in the earlier module, makes sure you sign exactly the image you looked at. Read the annotations back from a verified signature:

```sh
cosign verify --key /root/build/cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.14.1 | jq '.[] | .optional'
```

The signature you just made shows `built-by` and `pipeline`. The earlier signature from the playground set-up shows no annotations. Both verify, because both were made by the build key.

## Require an annotation when you verify

Verification without `-a` accepts any signature of the key. With `-a`, Cosign accepts only signatures that carry the annotation with that value:

```sh
cosign verify --key /root/build/cosign.pub --insecure-ignore-tlog=true -a built-by=ci harbor.localtest.me:8443/release/podinfo:6.14.1 >/dev/null && echo ok
cosign verify --key /root/build/cosign.pub --insecure-ignore-tlog=true -a built-by=someone-else harbor.localtest.me:8443/release/podinfo:6.14.1 >/dev/null || echo refused
```

The first command passes and the second does not. A pipeline that requires `-a` cannot be satisfied by an older signature without the claim.

## More than one signer

An artifact can have many signatures at once. Each signature is a separate accessory, and each verifies with its own public key. Sign the same digest with the security key and the annotation `approved-by=security`:

```sh
COSIGN_PASSWORD=security-signing-password cosign sign --yes --key /root/security/cosign.key \
  --use-signing-config=false --tlog-upload=false -a approved-by=security \
  "harbor.localtest.me:8443/release/podinfo@$DIGEST"
```

Check both signatures, each with its own key:

```sh
cosign verify --key /root/build/cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.14.1 >/dev/null && echo build-ok
cosign verify --key /root/security/cosign.pub --insecure-ignore-tlog=true -a approved-by=security harbor.localtest.me:8443/release/podinfo:6.14.1 >/dev/null && echo security-ok
cosign tree harbor.localtest.me:8443/release/podinfo:6.14.1
```

The new signature does not replace the first. It sits next to it, and the tree shows both. This is how a release gets a build signature and an approval signature that different teams control. A consumer that wants both runs two `cosign verify` commands, and an automated check that wants either accepts the first one that passes.

You now know how to attach a claim to a signature, how to require it, and how to add a second signer without touching the first. The graded lab uses all three.

## Common pitfalls

> [!WARNING]
> - **Signing a tag.** Cosign warns about it, and the tag can move. Sign the digest.
> - **Verifying without `-a` and trusting the claim.** Without the flag, the annotation is not checked.
> - **Using the build key for the approval.** Then one key vouches for both, and the second signature adds nothing.
> - **Forgetting the signing flags in a private environment.** Without `--use-signing-config=false --tlog-upload=false`, Cosign tries to reach the public Sigstore services.

## Your mission: Add A Second Signature With An Annotation

You can now sign a digest with a second key and an annotation. The graded lab gives you the project `release` with `6.14.1` and `6.15.0`, both signed by the build key, and an unused security key pair. It asks you to add a security signature with the annotation `approved-by=security` to both, and to leave the build signatures in place.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-030-02
astrona start ats-102-playground-030-02
```
