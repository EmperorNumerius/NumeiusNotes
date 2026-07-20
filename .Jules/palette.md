## 2024-07-20 - Adding IconButton with Tooltip instead of GestureDetector
**Learning:** Replacing `GestureDetector` wrapped icons with `IconButton` adds native tooltips and ARIA-like semantics for screen readers, but can disrupt layout by injecting default padding.
**Action:** Use `padding: EdgeInsets.zero` and `constraints: const BoxConstraints()` on the `IconButton` to maintain the existing layout while boosting accessibility.
