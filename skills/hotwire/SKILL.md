---
name: hotwire
description: Hotwire Turbo and Stimulus patterns for Rails. Load when turbo-rails gem present per stacks/rails profile.
user-invokable: false
---

# Hotwire (Turbo + Stimulus)

Load when `turbo-rails` in Gemfile ([stacks/rails](../stacks/rails/profile.yaml) `if_gem`).

## Turbo

- Prefer **Turbo Frames** for partial page updates; **Turbo Streams** for multi-target DOM updates.
- Forms: `data-turbo="false"` only when full page reload is required.
- Drive navigation enabled by default — test stream responses in request/system specs.

## Stimulus

- One controller per behaviour; `data-controller`, `data-action`, `data-*-target`.
- Keep controllers small; fetch JSON from Rails endpoints, do not embed secrets in JS.

## Testing

- Assert turbo-stream content type and DOM ids in request specs where applicable.
