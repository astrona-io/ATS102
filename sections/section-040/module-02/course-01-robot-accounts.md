# Robot Accounts

A person's password in a pipeline gives the pipeline everything the person can do, for as long as the password lives. A robot account gives it only what you list. This part creates robots at the project level, shows what Harbor stores, and covers the secret, which Harbor shows once.

## The parts of a robot

| Part | What it is |
| --- | --- |
| Level | `project` for one project, or `system` for several or all projects |
| Name | Harbor adds a prefix. A project robot named `ci-pull` in `inventory` becomes `robot$inventory+ci-pull` |
| Permissions | A list of resource and action pairs, per project, such as `repository` with `pull` |
| Duration | The number of days the robot lives. `-1` means it never expires |
| Secret | The password. Harbor returns it once, when you create the robot |

The prefix and the `$` matter. In a shell, put the name in single quotes, or `$inventory` expands to an empty string.

## Create a pull-only robot

Open a shell in the workstation on your machine:

<!-- astrona:playground:renew -->

```sh
kubectl -n workstation exec -it deploy/workstation -- sh
```

Define the helper, and create a robot that can pull from `inventory` and lives for 14 days:

```sh
API=https://harbor.localtest.me:8443/api/v2.0
api() { curl -fsS -u admin:Harbor12345 -H 'Content-Type: application/json' "$@"; }
api -X POST "$API/robots" -d '{"name":"deploy","level":"project","duration":14,"disable":false,"permissions":[{"kind":"project","namespace":"inventory","access":[{"resource":"repository","action":"pull"}]}]}' | tee /tmp/robot.json | jq '{id, name, creation_time, expires_at}'
SECRET=$(jq -r '.secret' /tmp/robot.json)
```

The response holds the secret. Harbor does not store it in a form it can show again, so the file `/tmp/robot.json` is the only copy until you refresh it. In a real pipeline you write the secret straight into a secret store and never print it.

## Read the robot back

```sh
api "$API/robots?q=name=~deploy" | jq '.[] | {id, name, level, duration, disable, permissions}'
```

The listing shows the permissions and the expiry, but never the secret. A system administrator can read every robot. The expiry date is `creation_time` plus the duration. A robot that has expired is refused like a wrong password.

## Refresh and disable

If a secret leaks or a pipeline changes owner, you replace the secret without recreating the robot. Send the new value with a `PATCH`:

```sh
ROBOT_ID=$(jq -r '.id' /tmp/robot.json)
api -X PATCH "$API/robots/$ROBOT_ID" -d '{"secret":"Newsecret-2026-Ab1"}'
```

The old secret stops working at once. The new secret must satisfy Harbor's password rules, which need upper-case and lower-case letters and a digit, and be at least eight characters long. To stop a robot without deleting it, send the full robot with `"disable":true` in a `PUT`; a disabled robot keeps its history and its permissions and cannot sign in.

## System-level robots

A system robot has `"level":"system"` and a list of permission entries, each with its own `namespace`. The namespace `*` means all projects. Use a project robot when one project is enough, because a smaller reach means a smaller leak.

You can now create a robot with exact permissions and a lifetime, read it back, and replace its secret. A robot is only useful when something signs in with it, which is also where its refusals show.

## Common pitfalls

> [!WARNING]
> - **Writing the name in double quotes.** The shell expands `$inventory`. Use single quotes.
> - **Losing the secret.** Harbor shows it once. Refresh to get a new one.
> - **Creating a robot that never expires.** A duration of `-1` is a standing credential.
> - **Giving a pull job push rights.** The pipeline then has more reach than its task.
