# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Retention policies

## Scenario

The project `inventory` collects every build of `podinfo`. It holds the tags `6.0.0`, `6.14.1` and `6.15.0`, pushed in that order. Nobody needs more than the two newest, and the team wants Harbor to enforce that with a retention policy and to clean up now.

Harbor runs at `https://harbor.localtest.me:8443`; sign in as `admin` with the password `Harbor12345`. The workstation pod has `regctl`, `curl` and `jq`. Open a shell in it:

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

## Your task

1. Create a retention policy for the project `inventory` with one enabled rule that keeps the two most recently pushed artifacts.
2. Dry run the policy and check that it would keep two of the three tags.
3. Run the policy for real and wait for it to finish.
4. Check which tags are left.

## Constraints

- Do not delete tags by hand. The deletion must come from the retention execution.
- Do not create an immutable tag rule.
- Do not change other projects.

## Done when

- The project has a retention policy with an enabled rule using the template `latestPushedK` with the value 2.
- `inventory/podinfo` has the tags `6.14.1` and `6.15.0`, and `6.0.0` is gone.
