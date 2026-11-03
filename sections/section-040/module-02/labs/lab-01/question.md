# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Deployment security

## Scenario

The deployment pipeline for `podinfo` signs in to Harbor with a team member's password and can push to any repository. The team wants a dedicated account for the pipeline that can only pull images from `inventory`, and that stops working after 30 days. The team also wants the release tags protected, so that a tag such as `6.15.0` always means the same image.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. The project `inventory` holds `inventory/podinfo:6.15.0`. Use a shell in the workstation pod:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Create a project robot account named `ci-pull` in `inventory`. It may only pull from repositories, and it expires in 30 days.
2. Save the robot's secret in the file `/root/ci-pull-secret.txt` in the workstation.
3. Create a tag immutability rule in `inventory` for all repositories and for tags that start with `6.`.

## Constraints

- The robot must have no permission other than `pull`.
- Harbor shows the secret only when the robot is created. If you lose it, refresh the secret or create the robot again.
- Do not change the project settings and do not delete artifacts.

## Done when

- The robot account `robot$inventory+ci-pull` exists, has only the `pull` action, and expires about 30 days after it was created.
- `/root/ci-pull-secret.txt` holds a secret that signs the robot in.
- `inventory` has an enabled immutability rule whose tag pattern starts with `6.`.
