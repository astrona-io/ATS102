# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster. You use it to open a shell in the workstation pod.
- **The astrona command-line tool.**
- **A web browser,** if you want to look at Harbor's web portal.

You do not need `cosign`, `regctl` or the `harbor` command-line tool on your machine. The workstation pod in every environment has them, in the versions the course uses, and it trusts Harbor's certificate. Each environment also installs Helm 3.22.1 itself, to install Harbor.

Harbor is a large system. Give your container engine at least **4 GiB** of memory for one environment. The first start of an environment takes up to **15 minutes**: it downloads Harbor's images from Docker Hub, the client tools from GitHub, the example artifacts and the Trivy vulnerability database from `ghcr.io`. Without outbound internet, those starts fail with errors that have nothing to do with Harbor.

## Working in the workstation

Almost every Harbor command on a page runs in a shell inside the workstation pod. Open it like this:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

The pages always say when a command runs "in the workstation shell" and when it runs "on your machine". Commands that change the cluster itself, such as `kubectl scale`, run on your machine.

To open Harbor's web portal, run this on your machine and leave it running:

```sh
kubectl -n harbor port-forward svc/harbor 8443:8443
```

Then open `https://harbor.localtest.me:8443` and sign in as `admin` with the password `Harbor12345`. These are lab-only credentials. The browser warns about the certificate, because the lab generates its own; a real installation uses a certificate your machines trust. The name `harbor.localtest.me` is a public DNS name that points at `127.0.0.1`, your own machine. If your router blocks such answers, add this line to `/etc/hosts`:

```
127.0.0.1 harbor.localtest.me
```

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS102.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It reads Harbor through its API and pulls artifacts the way a client does, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-102-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own Harbor. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

A start that seems stuck is usually still pulling Harbor's images or waiting for every Harbor component to report healthy; give it the full 15 minutes. If it fails while it downloads something, check your network first. Remember also that a lab that starts with a scan in an error state or a pull that Harbor refuses is often broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
