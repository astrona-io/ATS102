# Solution: Lock Down A Release Project

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: enforcement is on, both releases verify with the team key and pull, and `debug` is unsigned and refused.

## Step 1: Check the releases against the team key

Open a shell in the workstation on your machine:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, sign Cosign in and verify both releases with the team's public key:

```sh
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
for tag in 6.14.1 6.15.0; do
  cosign verify --key /root/team/cosign.pub --insecure-ignore-tlog=true "harbor.localtest.me:8443/release/podinfo:$tag" > /dev/null && echo "$tag: team key OK" || echo "$tag: not signed by the team key"
done
```

Both print "not signed by the team key". Both releases do have a Cosign signature; check with `/root/old-key/cosign.pub` and both verify. The signatures are real, just made with the wrong key.

## Step 2: See why enforcement alone would not help

Harbor's enforcement only checks that a Cosign signature exists. Both releases already have one, from the old key, so turning enforcement on now would let them through without the team's signature. That is why the team key must sign them, and why the pipeline still has to run `cosign verify` with the team key.

## Step 3: Sign both releases with the team key

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
export COSIGN_PASSWORD='team-signing-password'
for tag in 6.14.1 6.15.0; do
  digest=$(regctl image digest "harbor.localtest.me:8443/release/podinfo:$tag")
  cosign sign --yes --key /root/team/cosign.key --use-signing-config=false --tlog-upload=false "harbor.localtest.me:8443/release/podinfo@$digest"
done
```

Run the loop from step 1 again: both now print "team key OK". The old signatures stay as accessories next to the new ones; a verification with the team key needs only one matching signature.

## Step 4: Turn on enforcement

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor project config update release --enable-content-trust-cosign true
```

## Step 5: Prove it with pulls

```sh
for tag in 6.14.1 6.15.0 debug; do
  regctl manifest get "harbor.localtest.me:8443/release/podinfo:$tag" > /dev/null && echo "$tag: allowed"
done
```

Both releases are allowed. `debug` is refused with `412 Precondition Failed` and `The image is not signed by cosign.`.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Turn on enforcement and stop | Both releases pass with the old key's signatures, and nothing proves the team signed them |
| Replace `/root/team/cosign.pub` with the old public key | Verification "passes" with a key the team does not trust; the grader checks the original team key |
| Sign `debug` to make the pull test pass | `debug` becomes pullable, which the task forbids |
| Delete the old signatures first | Not needed: verification with the team key needs only one matching signature, and the old ones show who signed before |

## Common mistakes

- Signing by tag after someone moved the tag: you sign whatever the tag points at now. Sign the digest you checked.
- Forgetting `COSIGN_PASSWORD` for the team key. Cosign then asks for it and the loop stops.
