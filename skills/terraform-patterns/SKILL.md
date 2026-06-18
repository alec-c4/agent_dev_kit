---
name: terraform-patterns
description: Terraform patterns — modules, state, workspaces, IAM. Load for IaC and cloud infrastructure.
user-invokable: false
---

# Terraform patterns

Use when authoring Terraform modules and environment stacks.

## Structure

- **Modules** for reusable units; root modules per environment (`env/staging`, `env/production`).
- Pin **provider versions** in `required_providers`; lock file committed.
- Variables in `variables.tf`; outputs documented; no magic strings in resources.

## State

- Remote state (S3 + DynamoDB, GCS, Terraform Cloud) — **never** commit `terraform.tfstate`.
- State locking enabled; one state per environment or bounded blast radius.

## Safety

- `terraform plan` in CI on every PR; apply only from approved pipeline or manual gate.
- Avoid `lifecycle { prevent_destroy = false }` on production data stores without review.
- Least-privilege IAM — module-scoped roles, no `*` actions without justification.

## Style

- Run `terraform fmt` and `tflint` / `checkov` when project uses them.
- Use `for_each` / `count` thoughtfully; prefer explicit resources when readability wins.

## Do not

- Store secrets in tfvars committed to git.
- Run `terraform apply -auto-approve` on production without pipeline controls.

## References

- [Terraform docs](https://developer.hashicorp.com/terraform/docs)
