---
name: ansible-patterns
description: Ansible patterns — playbooks, roles, idempotency, inventory. Load for config management and server provisioning.
user-invokable: false
---

# Ansible patterns

Use when writing playbooks, roles, or Ansible-driven provisioning.

## Structure

- **Roles** over monolithic playbooks; `roles/<name>/tasks`, `handlers`, `defaults`, `vars`.
- **Inventory** per environment (`inventories/staging`, `inventories/production`) — no secrets in inventory git.
- **`ansible.cfg`** in repo root with sensible defaults (roles path, retry files off in CI).

## Idempotency

- Every task must be safe to re-run; use modules (`apt`, `template`, `systemd`) not raw `shell` unless necessary.
- Handlers for restart-on-change; notify only when config actually changes.

## Secrets

- **Ansible Vault** for encrypted vars; vault password from CI secret store, not repo.
- Document `ansible-vault edit` workflow in project README.

## Testing

- Run `ansible-playbook --check` (dry-run) in CI when feasible.
- Molecule or ansible-lint for roles when project already uses them.

## Do not

- Commit vault plaintext or SSH private keys.
- Use `ignore_errors: yes` without comment and follow-up task.

## References

- [Ansible docs](https://docs.ansible.com/)
