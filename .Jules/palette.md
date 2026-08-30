## 2024-05-24 - Accessible Close Tab Button
**Learning:** Icon-only buttons should use `IconButton` with a tooltip instead of `GestureDetector` for improved accessibility and to provide a hover state on desktop/web.
**Action:** Replace `GestureDetector` with `IconButton` for icon-only buttons, overriding padding and constraints to maintain original layout when in compact UI areas.
