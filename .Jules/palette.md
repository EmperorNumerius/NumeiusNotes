## 2024-05-15 - Tooltips on custom action icons
**Learning:** Added tooltips to custom icon-only actions (like closing tabs and note options menu) to improve accessibility, as these don't have default screen reader labels. This helps screen reader users identify the purpose of the buttons.
**Action:** Always wrap custom `GestureDetector` icon buttons with `Tooltip` when they don't have explicit labels.
