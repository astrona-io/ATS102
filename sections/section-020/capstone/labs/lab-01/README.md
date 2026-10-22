---
estimated_duration: 30m
---

# Ship A Release With A Report And An SBOM

- **ID:** LAB
- **Slug:** ats-102-capstone-020
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab on Harbor 2.15.4. Read `question.md` for the task; `solution.md` is
the walkthrough. The first start takes up to 15 minutes.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-102-capstone-020
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-102-capstone-020`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Harbor install and the starting state |
| `manifests/` | Helm values and the workstation pod |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Helpers `astrona test` runs first |
| `validation/` | Grading scripts, one per check |
