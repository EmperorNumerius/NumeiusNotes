## 2024-05-18 - Tooltips on IconButtons
**Learning:** Flutter `IconButton` inherently provides a tooltip property which sets an ARIA-like label for screen readers. Using `Tooltip` widget wrapping a `GestureDetector` works, but using `IconButton` natively provides a hover state on desktop/web and semantic ARIA-like label for screen readers seamlessly fulfilling accessibility requirements.
**Action:** Replace `GestureDetector` or `InkWell` wrapped with `Tooltip` (or just missing tooltips) with `IconButton` for icon-only buttons, especially in constrained compact UI areas like `TabManager`.
