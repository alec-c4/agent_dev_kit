---
name: hotwire
description: Hotwire Turbo and Stimulus patterns for Rails. Load when turbo-rails gem present per stacks/rails profile.
user-invokable: false
---

# Hotwire (Turbo + Stimulus)

Load when `turbo-rails` is in the Gemfile ([stacks/rails](../stacks/rails/profile.yaml) `if_gem`).

Often paired with [rails-importmaps](../rails-importmaps/SKILL.md) (no Node bundler) or [rails-js-bundling](../rails-js-bundling/SKILL.md).

## Turbo Drive

- Full-page navigations become **partial replacements** of `<body>` — keep persistent layout elements with `data-turbo-permanent` when needed.
- Disable Drive on specific links/forms: `data-turbo="false"` only when a full reload is required (external flows, non-HTML downloads).
- Use **`data-turbo-method`** / Rails `button_to` for non-GET — do not hand-roll DELETE links without CSRF.

## Turbo Frames

- One frame = one lazy or independently refreshable region (`turbo_frame_tag`).
- Target responses with matching `turbo_frame_request_id` — return **frame layout** only, not full application layout.
- Break out of frame with `data-turbo-frame="_top"` when redirecting to another section.

## Turbo Streams

- Prefer streams for **multi-target** updates (lists, counters, flash + list append).
- Standard verbs: `append`, `prepend`, `replace`, `update`, `remove` — match DOM ids in tests.
- Broadcasts (`turbo_stream_from`) for live updates — scope channels per record; authorize subscription.

## Stimulus

- **One controller per behaviour** — `app/javascript/controllers/` with `*_controller.js`.
- Actions via `data-action="click->hello#greet"`; targets via `data-*-target`; values via `data-*-value`.
- Fetch JSON from Rails endpoints; **CSRF** via meta tag / Rails UJS patterns; never embed secrets in JS.

## Testing

- Request specs: assert `text/vnd.turbo-stream.html` and stream actions for turbo-stream endpoints.
- System specs: assert frame ids and DOM updates after click/submit.
- Avoid sleeping — use Capybara matchers on visible content.

## References

- [Hotwire](https://hotwired.dev/)
- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
