## 2024-05-19 - Overflow on App Title Wrap
**Learning:** Hardcoding long titles next to icons inside of a Row without expanded/flexible constraint can easily trigger `RenderFlex` overflow errors on narrow windows or test environments with smaller viewports.
**Action:** Always wrap text elements next to fixed-width elements with `Expanded` or `Flexible` with `overflow: TextOverflow.ellipsis` inside a Row when building sidebars or app bars.
