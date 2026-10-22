# ATS102 — Content Trust, Vulnerability Scanning & SBOMs (Harbor)

Course material for the **Content Trust, Vulnerability Scanning & SBOMs**
domain of the Astrona Harbor training path
([ATP020](https://github.com/astrona-io/ATP020)), which is **25% of the
path**. Written for **Harbor v2.15.4**, the `harbor` CLI **v0.0.27** and
**Cosign 3.1.4**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Harbor 2.15 documentation, the Harbor v2.15.4 source code and the
> Cosign 3.1.4 documentation. None has been started on a cluster, and no lab
> has passed `astrona test` yet. See `CLAUDE.md` for the open questions.

The course opens with an Introduction in `sections/intro/` (welcome, machine
setup, how the course is made). Everything else lives under `sections/`. Each
section contains:

- **A module** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore
  in, and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab with several faults at once.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Vulnerability Scanning With Trivy | 1 | 1 + capstone | Scanning |
| [020](sections/section-020) | Software Bills Of Materials | 1 | 1 + capstone | SBOM |
| [030](sections/section-030) | Signing With Cosign And Enforcing Signatures | 1 | 1 + capstone | Content trust |
| [040](sections/section-040) | Blocking Vulnerable Artifacts And CVE Allowlists | 1 | 1 + capstone | Deployment security |

The order follows a release: first find what is wrong (scan), then record
what is inside (SBOM), then prove where it came from (sign), and last refuse
what is not safe (block).

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Scan Artifacts For Vulnerabilities With Trivy](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Generate And Read Software Bills Of Materials](sections/section-020/module-01/course.md) | 2 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Sign Artifacts With Cosign And Enforce Signatures](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Stop Vulnerable Artifacts From Being Pulled](sections/section-040/module-01/course.md) | 2 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Get A Successful Scan For Every Release | Trivy adapter scaled to zero, failed scans, scan on push off |
| [020](sections/section-020/capstone/labs/lab-01) | Ship A Release With A Report And An SBOM | missing scan, missing SBOMs, both automatic settings off |
| [030](sections/section-030/capstone/labs/lab-01) | Lock Down A Release Project | releases signed with an untrusted key, enforcement off, an unsigned debug tag |
| [040](sections/section-040/capstone/labs/lab-01) | Tighten A Project That Lets Everything Through | prevention off at `critical`, a reused blanket system allowlist with no expiry |

---

## The lab environment

Every playground and lab is a **kind** cluster with Harbor 2.15.4 installed by
the `harbor-helm` chart 1.19.4 (Helm 3.22.1), exposed in the cluster at
`https://harbor.localtest.me:8443` with a certificate the chart generates, and
a `workstation` pod with `harbor`, `cosign`, `regctl`, `oras`, `curl` and
`jq` that trusts that certificate. A CoreDNS `rewrite stop` block makes the
name resolve inside the cluster; `kubectl -n harbor port-forward svc/harbor
8443:8443` makes it answer on the reader's machine. The administrator is the
lab-only `admin` / `Harbor12345`.

Example content comes from `ghcr.io/stefanprodan/podinfo` (6.0.0, 6.14.1,
6.15.0), always copied for `linux/amd64` only, so that Harbor's deployment
security checks the image itself and not an image index.

The plumbing of all twelve environments (install, seed, solution, testing and
validation scripts, `config.yaml` files, author READMEs and prerequisites)
shares one helper block. Change a helper in every environment at once.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/<section>/module-01/playground
astrona destroy <name>
```

## Running a lab

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Graders pull manifests with `curl` against Harbor's token service and compare
the HTTP status (`200` or `412`), and they decide the expected status from the
artifact's live vulnerability report. Several graders reject the
plausible-but-wrong fix: allowlisting everything, raising the threshold,
signing the wrong artifact, or turning a policy off.
