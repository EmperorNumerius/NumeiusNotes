## 2024-05-18 - Replacing GestureDetector with IconButton in Compact UIs
**Learning:** Icon-only buttons implemented via GestureDetector lack essential accessibility features (ARIA/semantics) and interactive hover states. Using IconButton is better, but can break compact layouts if default padding isn't overridden.
**Action:** Use IconButton with padding: EdgeInsets.zero and explicit BoxConstraints(minWidth: X, minHeight: Y) to provide tooltips and hover states without regressions in tight layouts.
