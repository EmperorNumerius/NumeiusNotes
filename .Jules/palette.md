## 2024-05-18 - Tooltip/GestureDetector vs IconButton for accessibility
**Learning:** Using `Tooltip` wrapping a `GestureDetector` with an `Icon` child lacks a proper semantic ARIA-like label for screen readers and built-in hover/focus states for accessibility.
**Action:** Always prefer `IconButton` (which natively includes a `tooltip` property, proper minimum 48x48 touch targets when unconstrained, and keyboard focus support) over custom combinations of `Tooltip` and `GestureDetector` for icon-only interactive elements.
