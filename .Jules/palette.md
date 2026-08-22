## 2024-05-14 - Note Options Accessibility
**Learning:** Replaced `GestureDetector` wrapped around `Icon` with `IconButton` in `HomePage` Note cards. This inherently provides ARIA-like semantics and hover states for screen readers and web usage.
**Action:** Always prefer `IconButton` with `tooltip` for icon-only actions instead of manually implementing tap detection via `GestureDetector`. Use `padding: EdgeInsets.zero` and `constraints: const BoxConstraints()` to fit it in compact spaces like Note cards.
