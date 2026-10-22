# Preventing Vulnerable Images From Running

A report tells you an image is dangerous; a policy stops it from being used. Harbor's vulnerability prevention is that policy: a project setting that makes Harbor read the report on every pull and refuse artifacts that are too vulnerable. This part turns it on for `inventory`, reads the refusal, and walks through the three cases that surprise people the first time: an artifact that was never scanned, an image index, and the pulls that are exempt.

## Read the reports first

The policy acts on the reports, so start by looking at them. Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, define the API helper and print the worst severity and the count per severity of both releases:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
for tag in 6.0.0 6.15.0; do
  printf '%s ' "$tag"
  api "$API/projects/inventory/repositories/podinfo/artifacts/$tag?with_scan_overview=true" \
    | jq -c '.scan_overview[] | {severity, summary: .summary.summary}'
done
```

`6.0.0` has `High` or `Critical` as its worst severity and a list of counts. `6.15.0` has far fewer findings, often none at High or above. Remember both lines: they predict what the policy will do.

## Turn on vulnerability prevention

The setting has two parts. `prevent_vul` turns the check on, and `severity` sets the threshold: `low`, `medium`, `high` or `critical`. Harbor refuses an artifact when its worst finding is **at or above** the threshold. With `high`, an artifact with a High or a Critical finding is refused, and one with only Medium or Low findings is served.

Set both with the `harbor` command-line tool, signed in first:

```sh
harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin
harbor project config update inventory --prevent-vul true --severity high
harbor project config list inventory
```

The list shows `prevent_vul` as `true` and `severity` as `high`. In the web portal this setting is called "Prevent vulnerable images from running", which is a little misleading: Harbor cannot see what runs. It refuses the pull, and a cluster that cannot pull an image cannot run it.

## Pull and read the refusal

Pull the manifest of each release with `regctl`, the way a container runtime would:

```sh
regctl registry login harbor.localtest.me:8443 -u admin -p Harbor12345
regctl manifest get harbor.localtest.me:8443/inventory/podinfo:6.0.0 > /dev/null && echo "6.0.0 pulled"
regctl manifest get harbor.localtest.me:8443/inventory/podinfo:6.15.0 > /dev/null && echo "6.15.0 pulled"
```

The pull of `6.0.0` fails. Harbor answers `412 Precondition Failed` with the code `PROJECTPOLICYVIOLATION` and a message that starts `current image with` and a number of vulnerabilities, `cannot be pulled due to configured policy in 'Prevent images with vulnerability severity of "high" or higher from running.'`, and then asks you to contact the project administrator about a CVE allowlist. `6.15.0` pulls if its report has no High or Critical finding, and is refused the same way if it has.

The refusal came from `core`, which checks the policy on every manifest pull before the `registry` component answers. You pulled as the system administrator, and the policy refused you anyway: nobody is exempt by role.

## Three cases that surprise people

The policy is simple, but three cases behave differently from what most people expect, and each one has caused real outages or real gaps.

### An artifact that was never scanned

With the policy on, Harbor cannot judge an artifact that has no report, and it does not guess: it refuses it. Try it by pushing a release that nobody scans:

```sh
regctl image copy --platform linux/amd64 ghcr.io/stefanprodan/podinfo:6.14.1 harbor.localtest.me:8443/inventory/podinfo:6.14.1
regctl manifest get harbor.localtest.me:8443/inventory/podinfo:6.14.1 > /dev/null && echo "6.14.1 pulled"
```

The pull is refused with `412` and a message that the image has not been scanned and cannot be pulled under the configured policy. Scan it with `harbor artifact scan start inventory/podinfo/6.14.1` and pull again once the scan reads `Success`; the result then follows its report. This is why vulnerability prevention and scan on push belong together: without scan on push, every new release is refused until someone scans it.

### An image index

An **image index** is a manifest that lists one image per platform, such as `linux/amd64` and `linux/arm64`. Harbor scans the platform images, not the index, and the policy skips the index itself. A client that pulls a multi-platform tag gets the index first without a check, then pulls its platform image, and that pull is checked. So a vulnerable platform image is still refused, at the second step. Every artifact in this course is a single platform image, so a pull by tag is checked directly.

### Exempt pulls

Harbor's own scanner must pull an artifact to scan it, even a vulnerable one, so its pulls are exempt. Pulls by Cosign or Notation clients that sign the artifact are exempt from this check too. Every other pull is checked.

You now know how to turn vulnerability prevention on, how Harbor refuses a pull with `412`, and how to predict the result from the report. You also know the three surprises: unscanned artifacts are refused, an index is checked through its platform images, and the scanner's and signers' pulls are exempt. The open question is the exception: an artifact the business has reviewed and must keep running.

## Common pitfalls

> [!WARNING]
> - **Turning on prevention without scan on push.** Every new artifact is refused until someone scans it.
> - **Reading the threshold as "above".** It is "at or above": with `high`, a High finding blocks.
> - **Lowering the threshold to `critical` to make one image pull.** That lets every High finding in the project through. Use a narrow, expiring allowlist instead.
> - **Assuming administrators are exempt.** The policy refuses `admin` too.
