## 2024-05-15 - Missing Tooltips on Icon-Only Buttons
**Learning:** Found an icon-only button (note options menu) lacking a tooltip/ARIA label in a custom grid layout. Wrapping the existing interaction widget (`GestureDetector`) with a `Tooltip` is preferred over using an `IconButton` to prevent `RenderFlex` overflow errors caused by default sizing constraints.
**Action:** Always verify icon-only buttons have tooltips and prefer wrapping `GestureDetector` in custom dense layouts instead of using `IconButton` to maintain layout stability.
