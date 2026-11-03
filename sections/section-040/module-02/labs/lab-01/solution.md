# Solution: Create A Pull-Only Robot And Protect Release Tags

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the robot has only the pull action and lives about 30 days, the saved secret works, and the immutability rule exists.

## Step 1: Define the helper

In the workstation shell:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
```

## Step 2: Create the robot and save the secret in one step

Harbor returns the secret once, so write it to the file as soon as you create the robot:

```sh
api -X POST "$API/robots" -d '{"name":"ci-pull","level":"project","duration":30,"disable":false,"permissions":[{"kind":"project","namespace":"inventory","access":[{"resource":"repository","action":"pull"}]}]}' | jq -r '.secret' > /root/ci-pull-secret.txt
test -s /root/ci-pull-secret.txt && echo saved
```

`duration` is in days, so `30` gives a robot that expires in 30 days. If the command fails because the robot already exists, delete it first with `api -X DELETE "$API/robots/ID"`, or refresh its secret.

## Step 3: Check that the secret works

Single quotes keep the shell from expanding the `$` in the name:

```sh
curl -s -o /dev/null -w '%{http_code}\n' -u 'robot$inventory+ci-pull:'"$(cat /root/ci-pull-secret.txt)" 'https://harbor.localtest.me:8443/service/token?service=harbor-registry&scope=repository:inventory/podinfo:pull'
```

The status is `200`. Read the robot back to check the permissions and the expiry:

```sh
api "$API/robots?q=name=~ci-pull" | jq '.[] | {name, creation_time, expires_at, permissions}'
```

## Step 4: Create the immutability rule

```sh
api -X POST "$API/projects/inventory/immutabletagrules" -d '{"disabled":false,"action":"immutable","template":"immutable_template","scope_selectors":{"repository":[{"kind":"doublestar","decoration":"repoMatches","pattern":"**"}]},"tag_selectors":[{"kind":"doublestar","decoration":"matches","pattern":"6.*"}]}'
api "$API/projects/inventory/immutabletagrules" | jq '.[] | {disabled, tag_selectors}'
```

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Give the robot push as well | The check fails on any action other than `pull` |
| Use duration `-1` | The robot never expires, and the lifetime check fails |
| Forget to save the secret | The saved-secret check fails, and Harbor cannot show it again |
| Use the pattern `**` for tags | It protects every tag, and the check expects a pattern for `6.` |

## Common mistakes

- Writing the robot name in double quotes, so the shell removes `$inventory`.
- Reading `duration` as hours or seconds. It is in days.
- Creating the rule with `"disabled":true`.
