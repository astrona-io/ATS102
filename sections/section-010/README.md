# Section 010: Vulnerability Scanning With Trivy

A registry stores whatever it is given. Unless someone checks, an image with a known security flaw in one of its packages looks exactly like a safe one. Harbor closes that gap with a scanner: it looks inside each artifact, lists the packages it finds, and compares them with a database of known vulnerabilities.

This section shows you how that works and how to use it from the command line. Harbor comes with **Trivy**, an open source vulnerability scanner, already connected. You start a scan, read the report through the Harbor REST API, and then make Harbor scan every new artifact on its own, on push and on a schedule. Every later section depends on these reports: Harbor can only refuse a vulnerable artifact once it knows what is inside.

**Topic covered:** Vulnerability scanning

## What you will learn

- How Harbor's `core`, `jobservice` and `trivy` components work together to scan an artifact.
- What the Trivy vulnerability database is, and why the first scan of a new Harbor takes longer.
- Starting a scan with the `harbor` command-line tool and with the REST API.
- Reading a vulnerability report: the summary by severity and the list of CVEs with their packages and fixed versions.
- Turning on scan on push for a project, and scheduling a scan of every artifact.
- Finding why a scan ends in an error.

## The learning path

### 1. Scan Artifacts For Vulnerabilities With Trivy

The module starts at its landing page, which also launches the playground. The playground holds Harbor with the project `inventory` and two versions of the `podinfo` image that nobody has scanned yet.

1. How Harbor Scans Artifacts With Trivy
2. Scanning An Artifact And Reading The Report
3. Scan On Push And Scheduled Scans, followed by the lab **Scan Every Pushed Artifact**
4. Summary

## Section capstone: Get A Successful Scan For Every Release

The capstone is one graded scenario that puts the module together. Every scan in the project `release` ends in an error, nobody knows why, and new artifacts are not scanned at all. Find the cause, get a successful report for every release, and make sure the next push is scanned without anyone asking. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-102-capstone-010
```
