## 2024-05-14 - Prevent RenderFlex Overflows in Compact Sidebars
**Learning:** Fixed-width elements (like icons) adjacent to unconstrained text in a `Row` can cause `RenderFlex` overflow errors when tested on compact viewports, a common pattern in sidebars.
**Action:** Always wrap the text element inside the `Row` with an `Expanded` widget and add `overflow: TextOverflow.ellipsis` to gracefully handle narrow screen sizes, particularly during widget tests that simulate constrained widths.
