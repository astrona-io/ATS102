# Making A Project Refuse Unsigned Artifacts

A signature that nobody checks protects nothing. In practice, the safest place to check is the registry itself: if Harbor refuses to hand out an unsigned artifact, no cluster and no person can run it by mistake. This part turns on Cosign signature enforcement for the project `release`, pulls a signed and an unsigned artifact, and reads Harbor's refusal.

## Turn on enforcement

Cosign signature enforcement is the project metadata key `enable_content_trust_cosign`. The `harbor` command-line tool sets it with `harbor project config update`.

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, sign the `harbor` tool in and turn enforcement on:

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor project config update release --enable-content-trust-cosign true
harbor project config list release
```

The list now shows `enable_content_trust_cosign` as `true`. From this moment, `core` checks every manifest pull from `release`: an artifact without a `signature.cosign` accessory is refused.

## Pull the signed release and the unsigned candidate

Pull the manifest of each artifact with `regctl`, the way any client would. The release `6.15.0` is signed with the key pair in `/root`; the candidate `6.14.1-rc` is not:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl manifest get harbor.localtest.me:8443/release/podinfo:6.15.0 > /dev/null && echo "6.15.0 pulled"
regctl manifest get harbor.localtest.me:8443/release/podinfo:6.14.1-rc
```

The first command prints `6.15.0 pulled`. The second fails. Harbor answered with the HTTP status `412 Precondition Failed`, the error code `PROJECTPOLICYVIOLATION`, and the message `The image is not signed by cosign.`; `regctl` shows that error. You pulled as `admin`, the system administrator, and were still refused: the policy applies to everyone.

`412` is the code to look for in any client. Docker, containerd, Kubernetes and CI tools all report it in their own words, but the status and Harbor's message are the same.

## Who can still pull an unsigned artifact

One exception keeps signing possible. To sign, Cosign must first read the manifest it signs, and that manifest is still unsigned. Harbor therefore lets a Cosign or Notation client pull an unsigned manifest when the user can push to the project. Ordinary pulls get no such exception; only signing clients with push rights do. Harbor's own scanner pulls are exempt too.

So the order of a release process does not matter for signing. You can turn enforcement on first and sign afterwards, as long as the signer has push rights. Sign the candidate now and watch the refusal disappear. In the workstation shell, with the key pair from `/root`:

```sh
cd /root
export COSIGN_PASSWORD='lab-signing-password'
cosign login harbor.localtest.me:8443 -u admin -p Harbor12345
cosign sign --yes --key cosign.key --tlog-upload=false "harbor.localtest.me:8443/release/podinfo@$(regctl image digest harbor.localtest.me:8443/release/podinfo:6.14.1-rc)"
regctl manifest get harbor.localtest.me:8443/release/podinfo:6.14.1-rc > /dev/null && echo "6.14.1-rc pulled"
```

The candidate now pulls, because it has a Cosign signature. That is also the danger of signing: enforcement trusts any Cosign signature, made with any key. Harbor checks that a signature exists; checking that it was made with the team's key is the job of `cosign verify` with the team's public key, in the pipeline or in the cluster's admission control.

## Notation works the same way

The setting for Notation signatures is `enable_content_trust`, `--enable-content-trust` in the `harbor` tool. With it on, Harbor refuses artifacts without a `signature.notation` accessory, with the message `The image is not signed by notation.`. If both settings are on, an artifact needs both kinds of signature.

You can now make a project refuse unsigned artifacts, recognise the `412` refusal and its message, and explain who is exempt and why. You also know the limit: Harbor checks that a signature exists, not whose key made it.

## Common pitfalls

> [!WARNING]
> - **Testing enforcement as a signing client.** A Cosign client with push rights can pull an unsigned manifest. Test with an ordinary client such as `regctl`.
> - **Thinking `admin` is exempt.** The system administrator is refused like everyone else.
> - **Treating enforcement as key verification.** Harbor accepts a signature made with any key. Verify with your public key as well.
> - **Turning on both Cosign and Notation enforcement by accident.** Then every artifact needs two signatures.

## Your mission: Allow Only Signed Releases

You can now sign a release, make a project refuse unsigned artifacts, and prove both with real pulls. The graded lab gives you the project `release` with an unsigned release and an unsigned candidate, and asks you to sign only the release with a new key pair in `/root` and make the project refuse everything unsigned.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-102-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-102-lab-030-01
astrona start ats-102-playground-030-01
```
