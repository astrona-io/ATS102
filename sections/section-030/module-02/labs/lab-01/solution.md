# Solution: Add A Second Signature With An Annotation

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: both releases carry a security signature with the annotation, and both still verify with the build key.

## Step 1: Look at what exists

In the workstation shell, sign in and list the signatures of one release:

```sh
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
cosign tree harbor.localtest.me:8443/release/podinfo:6.15.0
```

One signature exists, from the build key. Check that the security check fails today:

```sh
cosign verify --key /root/security/cosign.pub --insecure-ignore-tlog=true -a approved-by=security harbor.localtest.me:8443/release/podinfo:6.15.0
```

Cosign reports that no matching signature was found.

## Step 2: Sign both releases with the security key

Sign the digest, not the tag, so the signature covers the image you looked at:

```sh
for ref in 6.14.1 6.15.0; do
  DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:$ref)
  COSIGN_PASSWORD=security-signing-password cosign sign --yes --key /root/security/cosign.key \
    --use-signing-config=false --tlog-upload=false -a approved-by=security \
    "harbor.localtest.me:8443/release/podinfo@$DIGEST"
done
```

`--use-signing-config=false --tlog-upload=false` keep Cosign from contacting the public Sigstore services.

## Step 3: Verify both signatures

```sh
for ref in 6.14.1 6.15.0; do
  cosign verify --key /root/security/cosign.pub --insecure-ignore-tlog=true -a approved-by=security harbor.localtest.me:8443/release/podinfo:$ref >/dev/null && echo "security ok $ref"
  cosign verify --key /root/build/cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:$ref >/dev/null && echo "build ok $ref"
done
```

Four lines print. If a line is missing, the matching signature or annotation is not there.

## Step 4: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign with the build key and the annotation | The security check uses the security public key and fails |
| Sign without `-a` | Verification with `-a approved-by=security` finds no matching signature |
| Delete the old signature first | The build check fails, and the task says to keep it |

## Common mistakes

- Using the wrong password for a key.
- Signing a tag instead of the digest.
- Forgetting to repeat the signing for the second release.
