## 2024-07-22 - Replace GestureDetector + Icon with IconButton for A11y
**Learning:** Using `GestureDetector` on an `Icon` sacrifices native screen reader support and tooltip functionality. Swapping to an `IconButton` gives these for free, but it often alters the layout by injecting default padding and constraints.
**Action:** When replacing a `GestureDetector` -> `Icon` pattern with `IconButton`, always set `padding: EdgeInsets.zero` and `constraints: const BoxConstraints()` on the `IconButton` to retain layout fidelity while boosting a11y.
