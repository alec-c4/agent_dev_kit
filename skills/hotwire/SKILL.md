---
name: hotwire
description: Hotwire Turbo and Stimulus patterns for Rails. Load when turbo-rails gem present per stacks/rails profile.
user-invocable: false
---

# Hotwire (Turbo + Stimulus)

Load when `turbo-rails` in Gemfile ([stacks/rails](../stacks/rails/profile.yaml) `if_gem`).

## Turbo

- Prefer **Turbo Frames** for partial page updates; **Turbo Streams** for multi-target DOM updates.
- Forms: `data-turbo="false"` only when full page reload is required.
- Drive navigation enabled by default — test stream responses in request/system specs.

### Page refreshes and morphing (Turbo 8)

- Opt in per layout with `<meta name="turbo-refresh-method" content="morph">`: a refresh then
  updates only the changed DOM nodes instead of replacing `<body>`. Pair it with
  `<meta name="turbo-refresh-scroll" content="preserve">` to hold scroll position.
- `<turbo-stream action="refresh">` triggers that refresh, taking `method="morph|replace"`
  and `scroll="preserve|reset"`.
- In Rails, `broadcasts_refreshes` on the model plus `turbo_stream_from` in the view replaces
  hand-written per-target broadcasts: the server sends one signal and the page morphs.
  Prefer it over broadcasting a stream per partial when the whole page reflects the change.
- Morphing preserves element identity — give list rows and stateful nodes stable `id`s, and
  mark anything the server must not touch with `data-turbo-permanent`.

## Stimulus

- One controller per behaviour; `data-controller`, `data-action`, `data-*-target`.
- Keep controllers small; fetch JSON from Rails endpoints, do not embed secrets in JS.

## Testing

- Assert turbo-stream content type and DOM ids in request specs where applicable.
- Morphing changes what a system test sees: assert on the updated node, not on a full
  page reload having happened.

## References

- [Turbo handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Page refreshes](https://turbo.hotwired.dev/handbook/page_refreshes)
- [Stimulus handbook](https://stimulus.hotwired.dev/handbook/introduction)
