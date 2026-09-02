---
name: retrospect
description: Turn closed findings into project lessons or a draft kit catalog entry. Never push to the kit remote.
user-invocable: true
---

# Retrospect

After verification PASSes, or when the human asks to capture a lesson.

## Steps

1. Read `.ai/work/{work_ref}-findings.md`. Skip rows that are still `open` or `regressed`.
2. For each `closed` + `block` fingerprint not yet in `.ai/lessons.md`:
   ```text
   ./scripts/kit lessons propose --fingerprint FINGERPRINT --guide "one sentence" --sensor SENSOR --stack STACK --source "{work_ref} F-n"
   ```
   First occurrence stays `pending` until `./scripts/kit lessons ack L-n`. Second occurrence auto-acks.
3. Optional user-global copy (fingerprint + guide + sensor only):
   ```text
   ./scripts/kit lessons promote L-n --global
   ```
4. Optional kit catalog: draft a **patch or PR body** against `registry/failure-patterns.yaml`. Include `fingerprint`, `stack`, one-line `guide`, tokens or sensor name. **Do not** git push, commit to the kit remote, or paste customer paths, secrets, or proper names.

## Do not

- Close findings from this skill (sensors / `--from-sensor` / human `--human` only).
- Copy file contents from the product repo into the kit catalog.
