# Solution: Allow Only Signed Releases

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: enforcement is on, the release is signed with your key and pulls, and the candidate is unsigned and refused.

## Step 1: Create the key pair

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell:

```sh
cd /root
export COSIGN_PASSWORD='choose-a-password'
cosign generate-key-pair
```

`/root/cosign.key` and `/root/cosign.pub` now exist.

## Step 2: Sign the release by its digest

Sign Cosign and `regctl` in, find the digest, and sign it without the transparency log:

```sh
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
DIGEST=$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.15.0)
cosign sign --yes --key cosign.key --use-signing-config=false --tlog-upload=false "harbor.localtest.me:8443/release/podinfo@$DIGEST"
```

Verify it with the public key:

```sh
cosign verify --key cosign.pub --insecure-ignore-tlog=true harbor.localtest.me:8443/release/podinfo:6.15.0
```

Cosign reports a verified signature.

## Step 3: Turn on enforcement

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor project config update release --enable-content-trust-cosign true
harbor project config list release
```

`enable_content_trust_cosign` reads `true`.

## Step 4: Prove it with pulls

```sh
regctl manifest get harbor.localtest.me:8443/release/podinfo:6.15.0 > /dev/null && echo "release pulled"
regctl manifest get harbor.localtest.me:8443/release/podinfo:6.14.1-rc
```

The release pulls. The candidate is refused: Harbor answers `412 Precondition Failed` with the message `The image is not signed by cosign.`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Sign every tag in the project | The candidate becomes pullable, which is exactly what the team wanted to prevent |
| Delete the candidate | The task keeps it; the point is that the policy refuses it |
| Sign without `--use-signing-config=false --tlog-upload=false` | Cosign tries to upload the signature details to the public Rekor log |
| Turn on Notation enforcement instead | Harbor then wants Notation signatures, and the Cosign-signed release is refused too |

## Common mistakes

- Generating the key pair in another folder. The grader looks for `/root/cosign.pub`.
- Testing the refusal with `cosign` instead of `regctl`. A signing client with push rights may pull an unsigned manifest.
- Verifying without `--insecure-ignore-tlog=true` after signing without the log.
