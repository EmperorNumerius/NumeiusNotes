## 2024-05-18 - Wrap long texts in Expanded
**Learning:** Found a RenderFlex overflow in widget tests due to a long breadcrumb row next to the search bar pushing content out of the constraints on smaller viewports.
**Action:** Always wrap flexible string components, especially those constructed dynamically like breadcrumbs, in `Expanded()` so they shrink rather than causing layout overflows.
