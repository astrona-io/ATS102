# Welcome To The Course

This course trains you for the **Content Trust, Vulnerability Scanning & SBOMs** part of the Astrona **Harbor** training path. That part is 25% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes and `kubectl`, and you know what a container image, a tag and a registry are. You can call a REST API with `curl` and pick fields out of JSON with `jq`. You do not need to know Harbor's security features yet. Each new idea is explained the first time it appears.

## What you can do at the end

A registry decides what a cluster is allowed to run. So this course does not ask you to remember words. It asks you to make Harbor refuse what is not safe to run, and to prove it with a real pull that Harbor refuses or allows. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **vulnerability scanning**. You will learn to:

- Explain how Harbor scans an artifact with its built-in Trivy adapter.
- Start a scan and read the vulnerability report from the command line.
- Scan every artifact automatically when it is pushed, and on a schedule.

A scan says what is wrong; a Software Bill of Materials (SBOM) says what is inside. So the second topic is **SBOMs**. You will learn to:

- Explain what an SBOM is and how Harbor stores it next to the artifact.
- Generate an SBOM by hand and on every push, then download and read it.

The third topic is **signing**. You will learn to:

- Sign an artifact with a Cosign key pair and verify the signature.
- Make a project refuse every artifact that has no Cosign signature.
- Explain what replaced Docker Content Trust and Notary in Harbor.

The fourth topic is **blocking vulnerable artifacts**. You will learn to:

- Make a project refuse pulls of artifacts with vulnerabilities at or above a severity.
- Write a CVE allowlist for a reviewed exception, with an expiry.

Everything is written for **Harbor v2.15.4**, the `harbor` command-line tool **v0.0.27** and **Cosign 3.1.4**.

## The words this course uses

The pages use Harbor's, Trivy's and Cosign's own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

An **artifact** is anything Harbor stores in the Open Container Initiative (OCI) format: a container image, a Helm chart, a signature. A **project** is Harbor's unit of access control; every repository lives in one. A **vulnerability** is a known security flaw in a software package, and a **CVE** is its public identifier in the Common Vulnerabilities and Exposures list. An **accessory** is an artifact that Harbor attaches to another artifact, for example a signature or an SBOM.

Three project settings come back again and again:

| Setting | What it does |
| --- | --- |
| Scan on push | Scans every new artifact as soon as it arrives |
| Cosign signature enforcement | Refuses pulls of artifacts without a Cosign signature |
| Prevent vulnerable images from running | Refuses pulls of artifacts with vulnerabilities at or above a severity |

## The example setup in your playground

Every playground and lab runs the same setup. Harbor runs inside a small Kubernetes cluster and answers at `https://harbor.localtest.me:8443`. A pod called `workstation` holds the client tools: the `harbor` command-line tool, `cosign`, `regctl`, `oras`, `curl` and `jq`. It already trusts Harbor's certificate, so you run your Harbor commands in a shell inside it.

The example artifact is `podinfo`, a small web application. The project `inventory` holds three versions of it: `6.0.0` is old and has many known vulnerabilities, while `6.14.1` and `6.15.0` are recent. Some modules add the projects `release` and `legacy`. Many labs start with something switched off or broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with finding problems, then describes what is inside an artifact, then proves where an artifact came from, and ends with refusing what is not safe.

| Section | What it covers |
| --- | --- |
| 010 | Vulnerability Scanning With Trivy |
| 020 | Software Bills Of Materials |
| 030 | Signing With Cosign And Enforcing Signatures |
| 040 | Blocking Vulnerable Artifacts And CVE Allowlists |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
