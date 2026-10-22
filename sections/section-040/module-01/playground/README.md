# Stop Vulnerable Artifacts From Being Pulled — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-102-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single sandbox environment with Harbor 2.15.4 and the workstation pod. It
spins up, prepares the module's starting state, and stays running so you can
explore. Nothing to submit. The first start takes up to 15 minutes.

## Run it

```sh
astrona run -c .
astrona destroy ats-102-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-102-playground-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (bootstrap only) |
| `bootstrap/prepare.sh` | Installs Harbor and the workstation, then seeds the starting state |
| `manifests/harbor-values.yaml` | Helm values for Harbor |
| `manifests/lab-start.yaml` | The workstation pod |
| `docs/overview.md` | What the environment contains and ideas to try |
