## 2024-11-04 - IconButton Accessibility
**Learning:** Icon-only buttons implemented with `GestureDetector` or `InkWell` often lack semantic meaning for screen readers. Using Flutter's `IconButton` with a `tooltip` attribute is preferred for accessibility because it provides proper touch targets, hover states, and screen reader labels.
**Action:** Replace `GestureDetector` and `InkWell` for icon-only interactive elements with `IconButton(..., tooltip: '...')` to improve accessibility out-of-the-box.
