## 2024-05-24 - Missing Tooltip on Icon-Only Buttons
**Learning:** In Flutter, using `InkWell` or `GestureDetector` directly with icon-only children leads to missing accessibility labels and tooltips, which are critical for screen readers and usability.
**Action:** Always wrap interactive icon-only elements in a `Tooltip` (or use `IconButton` with a `tooltip` property) to provide context and improve accessibility without breaking tight layout constraints.
