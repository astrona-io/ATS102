# Section 040: Blocking Vulnerable Artifacts And CVE Allowlists

A vulnerability report that nobody acts on changes nothing. The image with three Critical findings still pulls, and a cluster still runs it. Harbor can act on the report itself: a project setting makes Harbor refuse to hand out any artifact whose report shows vulnerabilities at or above a chosen severity.

Real teams also need exceptions. A finding may not apply to how the image is used, or a fix may be weeks away for an image the business cannot stop running. Harbor handles that with **CVE allowlists**: lists of CVE IDs that Harbor ignores when it decides, at system or project level, with an expiry date. This section teaches both, and how to keep the exceptions narrow.

**Topic covered:** Deployment security

## What you will learn

- The project setting "Prevent vulnerable images from running" and how its severity threshold works.
- Harbor's refusal of a vulnerable or unscanned artifact, and which pulls are exempt.
- Why an image index passes the check and its platform images do not.
- System and project CVE allowlists, how a project chooses between them, and what an expiry does.
- Building a narrow allowlist from a report with `jq`.

## The learning path

### 1. Stop Vulnerable Artifacts From Being Pulled

The module starts at its landing page, which also launches the playground. The playground holds Harbor with the project `inventory` and two scanned versions of the `podinfo` image, one old and one recent.

1. Preventing Vulnerable Images From Running
2. CVE Allowlists With An Expiry, followed by the lab **Block High Risk, Allow A Reviewed Exception**
3. Summary

## Section capstone: Tighten A Project That Lets Everything Through

The capstone is one graded scenario. The project `inventory` should refuse vulnerable images, but an old image with Critical findings pulls without complaint. More than one setting is to blame, and one of them is not in the project at all. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-102-capstone-040
```
