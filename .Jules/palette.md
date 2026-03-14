## 2026-03-14 - Adding Tooltips to custom icon buttons
**Learning:** Custom UI controls like `GestureDetector` or `InkWell` that wrap an `Icon` do not automatically provide accessibility labels. When creating custom icon buttons, wrapping them in a `Tooltip` is crucial as it adds an ARIA label for screen readers and provides visual context on hover.
**Action:** Always wrap custom icon-only buttons (using `InkWell`, `GestureDetector`, etc) with a `Tooltip(message: '...')` widget to ensure screen reader compatibility and better desktop hover experience.
