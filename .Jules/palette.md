## 2024-08-27 - App Title Text Overflow in Narrow Viewports
**Learning:** In narrow viewports (e.g., during tests), static text elements in a row next to fixed-width icons can cause `RenderFlex` overflows if they don't wrap or truncate.
**Action:** Always wrap text elements in `Expanded` or `Flexible` with `overflow: TextOverflow.ellipsis` when placed alongside other items in constrained layouts like sidebars.
