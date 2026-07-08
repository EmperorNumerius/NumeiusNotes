## 2024-07-08 - RenderFlex Fix
**Learning:** Fixing RenderFlex overflows in dynamic horizontal lists (like breadcrumbs) next to constrained elements (like search bars) requires wrapping the Row in a Flexible containing a SingleChildScrollView(scrollDirection: Axis.horizontal) to prevent layout regressions.
**Action:** Use this pattern to fix horizontal list overflow issues in Flutter UI files.
