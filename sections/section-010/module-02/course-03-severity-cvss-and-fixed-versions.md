# Severity, CVSS Scores And Fixed Versions

A report with two hundred lines is not a to-do list. The owner of the image needs to know which findings to fix first, and whether a fix exists. Each finding carries the data for that decision: a severity, a score, the package and its versions. This part names those fields and shows how to turn a long report into a short list that someone can act on.

## The fields of one finding

Harbor stores the report as a list of findings, one for each CVE and package pair. The most useful fields are these:

| Field | What it holds |
| --- | --- |
| `id` | The CVE identifier, for example `CVE-2023-1234` |
| `package` | The name of the affected package |
| `version` | The version of the package that is in the image |
| `fix_version` | The first version that fixes the flaw, or an empty value when no fix exists |
| `severity` | `Critical`, `High`, `Medium`, `Low`, `Negligible`, `Unknown` or `None` |
| `preferred_cvss` | The CVSS vectors and scores that Trivy chose as the main ones |
| `links` | Addresses of the advisories |
| `description` | A short text about the flaw |

The **Common Vulnerability Scoring System (CVSS)** gives a flaw a score from `0.0` to `10.0`. The score comes from a vector, a short string that records how the flaw is exploited: over the network or locally, how hard it is, and what it can damage. In version 3 of the system, `0.1` to `3.9` is Low, `4.0` to `6.9` is Medium, `7.0` to `8.9` is High, and `9.0` to `10.0` is Critical.

## Why the severity can differ from the score

The `severity` field is not always the band of the score. Trivy takes the severity from the data source it trusts most for the operating system. A distribution such as Alpine rates a flaw for its own packages, and that rating can differ from the rating of the National Vulnerability Database. Harbor shows the severity Trivy chose. The score is shown next to it, so you can see both when they disagree.

This matters for policy. Harbor's rule that refuses a pull compares the `severity`, not the score. A flaw with a score of `7.5` and the severity `Medium` does not trigger a rule set at `High`.

## Read a short list from a long report

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

In the workstation shell, define the helper, start the scan of `6.0.0` if it has no report yet, and wait for the status `Success`:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api -X POST "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/scan"
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0?with_scan_overview=true" | jq '[.scan_overview[]?.scan_status][0]'
```

Start with the number of findings in each severity. `group_by` collects the findings with the same severity, and `length` counts them:

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq '[.[].vulnerabilities[]] | group_by(.severity) | map({severity: .[0].severity, count: length})'
```

The result is one object for each severity that occurs. The numbers match the summary of the scan overview, because both come from the same report.

Now build the list for an owner. Keep only the Critical and High findings that have a fixed version, and show the package, its two versions and the score:

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq -r '[.[].vulnerabilities[]
      | select(.severity == "Critical" or .severity == "High")
      | select((.fix_version // "") != "")
      | {id, package, version, fix_version, score: (.preferred_cvss.score_v3 // .preferred_cvss.score_v2 // 0)}]
      | sort_by(-.score) | .[] | [.id, .package, .version, .fix_version, .score] | @tsv'
```

The list starts with the highest score. Each line says which package to update, from which version, and to which. The expression `.preferred_cvss.score_v3 // .preferred_cvss.score_v2 // 0` uses the version 3 score when it exists, then the version 2 score, and `0` when neither is present.

## Group by package

An owner fixes packages, not CVEs. Many findings share a package, and one update closes all of them. Group by package and show the highest fixed version for each:

```sh
api "$API/projects/inventory/repositories/podinfo/artifacts/6.0.0/additions/vulnerabilities" \
  | jq -r '[.[].vulnerabilities[] | select((.fix_version // "") != "")]
      | group_by(.package)
      | map({package: .[0].package, installed: .[0].version, findings: length, fix_versions: ([.[].fix_version] | unique)})
      | sort_by(-.findings) | .[] | [.package, .installed, .findings, (.fix_versions | join(","))] | @tsv'
```

The first lines name the packages that cause the most findings. Updating those few packages removes most of the report. The `fix_versions` column can hold more than one version when different flaws were fixed in different releases. The owner takes the highest one.

You can now read the fields of a finding, explain the difference between a severity and a score, and turn a long report into a list of packages to update. What a report cannot tell you is why a scan is missing or stuck, which is the last part of this module.

## Common pitfalls

> [!WARNING]
> - **Sorting by severity name.** The names sort in alphabetical order, not by risk. Compare with `select` or sort by score.
> - **Assuming a score of 9.0 or more is always `Critical`.** Harbor shows the severity of the data source, so the two can differ.
> - **Counting findings as if each were a different flaw.** One CVE can appear for several packages.
> - **Treating an empty `fix_version` as an error.** It means no fixed version exists yet.
