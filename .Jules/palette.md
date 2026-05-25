## 2024-05-25 - Breadcrumb renderflex overflow fix
**Learning:** Found a specific issue with the UI component causing `RenderFlex` overflow errors on smaller screens because a flexible area was not bounded using `Flexible` or scrolled in `SingleChildScrollView`.
**Action:** When working on horizontal breadcrumb navigation components, wrap the entire row in a `Flexible` containing a `SingleChildScrollView(scrollDirection: Axis.horizontal)` to prevent clipping and overflow, rather than just `Expanded`.
