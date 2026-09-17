## 2024-05-18 - Missing Accessibility Labels on Icon Buttons in Grids
**Learning:** Dense grid layouts in Flutter often use `GestureDetector` or `InkWell` directly on an `Icon` to save space, but this drops the accessibility and tooltip benefits of `IconButton`.
**Action:** Always wrap these custom icon-only tap targets with a `Tooltip` widget to provide hover text and semantic labels without altering the layout constraints.
