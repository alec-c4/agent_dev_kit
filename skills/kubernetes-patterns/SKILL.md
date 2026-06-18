---
name: kubernetes-patterns
description: Kubernetes (k8s) patterns — workloads, networking, config, GitOps. Load for cluster manifests and deploy automation.
user-invokable: false
---

# Kubernetes patterns

Use when writing manifests, Helm charts, or k8s deploy pipelines.

## Workloads

- **Deployments** with rolling updates; set `resources.requests/limits` on every container.
- **Probes** — liveness vs readiness; readiness must reflect dependency availability.
- **PodDisruptionBudgets** for HA services; anti-affinity for spread when needed.

## Config and secrets

- ConfigMaps for non-secret config; **Secrets** or external secret operators for credentials — never plain text in git.
- Mount secrets as files or env from references, not copied into images.

## Networking

- **Services** and **Ingress** (or Gateway API) with TLS termination documented.
- NetworkPolicies when cluster policy requires least-privilege pod traffic.

## Operations

- Label consistently (`app`, `component`, `version`); one owner per manifest directory.
- Prefer GitOps (Argo CD, Flux) over manual `kubectl apply` for production.

## Do not

- Deploy `:latest` without digest pin in production.
- Run privileged pods without explicit review.

## References

- [Kubernetes docs](https://kubernetes.io/docs/)
