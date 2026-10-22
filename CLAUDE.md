# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS102 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Content Trust, Vulnerability Scanning & SBOMs**
  domain of the **Harbor** training path (`ATP020`). It is 25% of the path.
  There is no official Harbor certification exam; the path's domains and
  weights are Astrona's own, set in `ATP020/path.yaml`.
- **What the domain really tests:** making Harbor refuse what is not safe to
  run, and proving it. The student must *do* things: scan an artifact and read
  the report, turn on scan on push, generate and read a Software Bill of
  Materials (SBOM), sign an artifact with Cosign, make a project refuse
  unsigned or vulnerable artifacts, and write a CVE allowlist with an expiry.
  Every fix is proved with a real pull that Harbor refuses (`412`) or allows
  (`200`), and with the report or accessory Harbor stores.
- **The four topics:** vulnerability scanning with Trivy, SBOMs, signing with
  Cosign and enforcing signatures, and blocking vulnerable artifacts with CVE
  allowlists.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Vulnerability Scanning With Trivy | Scanning |
  | 020 | Software Bills Of Materials | SBOM |
  | 030 | Signing With Cosign And Enforcing Signatures | Content trust |
  | 040 | Blocking Vulnerable Artifacts And CVE Allowlists | Deployment security |

- **The versions:** **Harbor v2.15.4** (chart `harbor-helm` 1.19.4, Helm
  3.22.1) on a single-node `kind` cluster, with the built-in Trivy adapter;
  the **`harbor` CLI v0.0.27**; **`cosign` 3.1.4**, `oras` 1.3.5 and `regctl`
  0.11.7 in the workstation pod. Do not teach fields, flags or output from
  other versions without saying so.
- **The main sources:** the Harbor 2.15 documentation,
  <https://goharbor.io/docs/2.15.0/>, the Harbor REST API v2.0 (Swagger file
  `api/v2.0/swagger.yaml` in `goharbor/harbor` at tag `v2.15.4`), the Harbor
  CLI documentation (`doc/cli-docs/` in `goharbor/harbor-cli` at `v0.0.27`),
  and the Cosign documentation (`doc/` in `sigstore/cosign` at `v3.1.4`).

### Status: built, not yet run

The first version of this repository was written from the documentation and
the Harbor source code **without a live run**. No playground or lab has been
started, and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The open questions, most important first:

1. **Cosign 3 without the transparency log.** Cosign 3 stores signatures as
   OCI 1.1 referring artifacts in the new bundle format and uploads to the
   public Rekor log by default. The course signs with `--tlog-upload=false`
   (shown in the `cosign sign` examples of v3.1.4, but not in its option list)
   and verifies with `--insecure-ignore-tlog=true`. Harbor 2.15.4 recognises
   the bundle artifact type `application/vnd.dev.sigstore.bundle.v0.3+json`
   as a Cosign signature (`src/server/middleware/subject/subject.go`). Check
   that signing works offline and that the accessory type is
   `signature.cosign`.
2. **The Trivy database download.** The first scan downloads the Trivy
   vulnerability database from `mirror.gcr.io/aquasec/trivy-db` (or
   `ghcr.io/aquasecurity/trivy-db` as the fallback, chart value
   `trivy.dbRepository`). Every seed scans one artifact in the project
   `warmup` first, and scripts wait up to 15 minutes for a report.
3. **The exact CVE list of `podinfo:6.0.0`.** No page names a CVE ID; pages
   and graders read the list from the live report.
4. The `harbor` CLI is young (`v0.0.x`). Check every command against
   `harbor <command> --help` of v0.0.27.

### Facts checked in the Harbor 2.15.4 source

These come from the code, not from memory. Keep them exact:

- **Project metadata keys** (`PUT /api/v2.0/projects/{name}` with
  `{"metadata": {...}}`, all values are strings): `auto_scan`,
  `auto_sbom_generation`, `prevent_vul`, `severity` (`none`, `low`,
  `medium`, `high`, `critical`), `enable_content_trust_cosign`,
  `enable_content_trust` (the Notation policy since Harbor 2.9),
  `reuse_sys_cve_allowlist`.
- **Refused pulls** answer `412 Precondition Failed` with the error code
  `PROJECTPOLICYVIOLATION`. Messages: `The image is not signed by cosign.`,
  `The image is not signed by notation.`, and for vulnerabilities
  `current image with N vulnerabilities cannot be pulled due to configured
  policy in 'Prevent images with vulnerability severity of "high" or higher
  from running.' ...`. An artifact that is not scanned yet is refused too.
- **Who is exempt:** the scanner's own pulls and Cosign or Notation pulls
  from a user who can push (so a signer can pull an unsigned manifest to sign
  it). The system administrator is **not** exempt.
- **Image indexes skip the vulnerability check**; the check runs on the
  platform manifests. Every environment therefore copies a **single platform**
  (`regctl image copy --platform linux/amd64`), so a pull by tag is checked.
- **SBOMs** are SPDX JSON (`application/spdx+json`), stored as an accessory of
  type `sbom.harbor` with artifact type `application/vnd.goharbor.harbor.sbom.v1`.
  `GET .../artifacts/{ref}?with_sbom_overview=true` gives
  `sbom_overview.sbom_digest`. Request one with
  `POST .../artifacts/{ref}/scan` and the body `{"scan_type": "sbom"}`.
- **Vulnerability reports:** `GET .../artifacts/{ref}/additions/vulnerabilities`;
  the summary is in `?with_scan_overview=true`.
- **CVE allowlists:** system level at `/api/v2.0/system/CVEAllowlist`
  (`harbor cve-allowlist add`), project level in the project's
  `cve_allowlist` field (`items[].cve_id`, `expires_at` in seconds since the
  epoch). A project uses its own list only when `reuse_sys_cve_allowlist` is
  `"false"`. An expired allowlist is ignored.
- **Notary v1 (Docker Content Trust)** was deprecated in Harbor 2.6.0 and
  removed in **2.9.0**. Teach it as history only.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Vulnerability / CVE | A known security flaw in a software package / its public identifier in the Common Vulnerabilities and Exposures list, for example `CVE-2023-1234` |
| Severity | Harbor's rating of a vulnerability: `Critical`, `High`, `Medium`, `Low`, `Unknown` (and `None` when nothing was found) |
| Scanner / Trivy adapter | The service Harbor calls to scan an artifact / the built-in `trivy` component that runs Trivy for Harbor |
| Trivy database | The vulnerability data the Trivy adapter downloads (from `mirror.gcr.io`, with `ghcr.io` as the fallback), rebuilt upstream every 12 hours |
| Scan on push | The project setting that scans every new artifact as soon as it is pushed (`auto_scan`) |
| SBOM | A Software Bill of Materials: the list of packages inside an artifact; Harbor writes it in the SPDX format |
| Accessory | An artifact Harbor attaches to another artifact, its subject: a signature, an SBOM |
| Cosign key pair | `cosign.key` (private, encrypted with a password) and `cosign.pub` (public), made with `cosign generate-key-pair` |
| Keyless signing | Signing with a short-lived certificate from an OpenID Connect identity instead of a stored key; needs the public Sigstore services |
| Transparency log (Rekor) | A public, append-only log of signatures that Cosign uploads to by default |
| Notation / Notary Project | The CNCF Notary Project's signing tool; Harbor can enforce Notation signatures as well as Cosign ones |
| Deployment security | The project settings that refuse pulls: signature enforcement and "Prevent vulnerable images from running" |
| CVE allowlist | A list of CVE IDs that Harbor ignores when it decides whether an artifact is too vulnerable, with an optional expiry |

### The example workloads

| Name | What it is |
| --- | --- |
| Harbor (namespace `harbor`) | Harbor 2.15.4 at `https://harbor.localtest.me:8443`, administrator `admin` / `Harbor12345` (lab-only) |
| `workstation` (namespace `workstation`) | `alpine:3.22` with `harbor`, `cosign`, `oras`, `regctl`, `curl` and `jq`, and Harbor's CA trusted |
| Project `inventory` | Private project with `inventory/podinfo` tags `6.0.0` (old, many known vulnerabilities), `6.14.1` and `6.15.0`, each copied for `linux/amd64` only from `ghcr.io/stefanprodan/podinfo` |
| Project `release` | Private project for signed, scanned releases (sections 030 and the capstones) |
| Project `legacy` | Private project for an approved exception (section 040) |

Pages run Harbor commands in a shell inside the workstation, the way a
continuous integration (CI) runner would, and say so every time the reader
switches between "on your machine" and "in the workstation shell":

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Inside that shell, a page that calls the REST API defines one helper first:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api "$API/projects/inventory" | jq .metadata
```

The `harbor` CLI v0.0.27 signs in with
`harbor login https://harbor.localtest.me:8443 --username admin --password Harbor12345 --context-name lab-admin`
(`--context-name`, never `--name`); saved credentials are managed with
`harbor context list|switch|get|update|delete`, and `harbor config` is Harbor's
server-side configuration, not the CLI's. In the workstation the CLI warns
that no system keyring exists and falls back to `~/.harbor/keyring/`.

Keys made with `cosign generate-key-pair` live in `/root` in the workstation
and never leave it. The repository never holds a private key.

### Environment facts the text must respect

- Everything in the ATS100 `CLAUDE.md` "Environment facts" holds: one address
  `https://harbor.localtest.me:8443`, the CoreDNS `rewrite stop` block (never
  the one-line `rewrite name` form), the workstation trusts Harbor's CA,
  never `--insecure`, no pulls from Harbor by the kind node, internet needed,
  about 4 GiB and up to 15 minutes to start.
- **Graders read status codes, not tool messages.** A grader asks the token
  service (`/service/token?service=harbor-registry&scope=repository:<repo>:pull`)
  for a token and sends `GET /v2/<repo>/manifests/<tag>` with `curl`, then
  compares the HTTP status (`200` or `412`). Pages show the same pull with
  `regctl manifest get` and describe Harbor's refusal in words.
- **Graders decide the expected result from the live report.** Which
  artifacts are vulnerable depends on the Trivy database of the day, so a
  grader reads the report first and then expects `412` or `200` from it.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/harbor-values.yaml`,
`manifests/lab-start.yaml`, `docs/overview.md`), labs (`config.yaml`,
`README.md`, `prerequisites.md`, `question.md`, `solution.md`,
`bootstrap/01-install-harbor.sh`, `bootstrap/02-seed-state.sh`, `manifests/`,
`solution/apply.sh`, `testing/wait-for-harbor.sh`, `validation/validate-*.sh`)
and one capstone per section.

The plumbing scripts (install, seed, testing, solution and validation
scripts, `config.yaml` files, author READMEs, `prerequisites.md`) share the
same helper block. Change a helper in every environment at once.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS102`, domain `Content Trust, Vulnerability Scanning
& SBOMs`, weight `25`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `scanning`, `sbom`, `signing`,
  `deployment-security`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `trivy`, `scanner`, `scan-on-push`,
  `scan-all`, `vulnerability-report`, `severity`, `security-hub`, `sbom`,
  `spdx`, `accessory`, `cosign`, `cosign-key-pair`, `notation`,
  `content-trust`, `signature-enforcement`, `prevent-vulnerable`,
  `cve-allowlist`, `allowlist-expiry`, `harbor-cli`, `harbor-api`, `regctl`,
  `digest`.
- `resources`: 1 to 4 pages on `goharbor.io` or `docs.sigstore.dev`. The only
  place outside links are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-010/module-01/playground
astrona destroy ats-102-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-102-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-102-playground-<section>-<module>`, `ats-102-lab-<section>-<module>`,
`ats-102-capstone-<section>`. Graders check **behaviour** and reject the
plausible but wrong fix: allowlisting every CVE, lowering the severity
threshold to `critical` or `none` to make a pull work, turning signature
enforcement off, deleting the vulnerable artifact, or signing the wrong
digest. A lab's `question.md` and `solution.md` must match what its
`validation/` scripts check.

### Where to find trusted sources

- **Scanning:** [vulnerability scanning](https://goharbor.io/docs/2.15.0/administration/vulnerability-scanning/),
  [scan individual artifacts](https://goharbor.io/docs/2.15.0/administration/vulnerability-scanning/scan-individual-artifact/),
  [system CVE allowlist](https://goharbor.io/docs/2.15.0/administration/vulnerability-scanning/configure-system-allowlist/),
  [deployment security](https://goharbor.io/docs/2.15.0/administration/vulnerability-scanning/deployment-security/)
- **SBOM:** [SBOM generation](https://goharbor.io/docs/2.15.0/administration/sbom-integration/)
- **Signing:** [sign artifacts](https://goharbor.io/docs/2.15.0/working-with-projects/working-with-images/sign-images/),
  [implementing content trust](https://goharbor.io/docs/2.15.0/working-with-projects/project-configuration/implementing-content-trust/),
  [Cosign signing](https://docs.sigstore.dev/cosign/signing/signing_with_containers/)
- **Projects:** [project configuration](https://goharbor.io/docs/2.15.0/working-with-projects/project-configuration/)
- **The landscape:** <https://www.cncf.io/projects/harbor/> (graduated).
