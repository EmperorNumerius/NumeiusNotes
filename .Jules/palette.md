## 2023-10-27 - Icon Accessibility in TabManager
**Learning:** Replaced `GestureDetector`/`InkWell` icon buttons with accessible `IconButton`s containing tooltips. This is critical for users on screen readers and for hover state visual feedback on desktop/web while ensuring layout constraints are preserved using `BoxConstraints`.
**Action:** Always prefer `IconButton` with `tooltip` for actionable icons over raw icon widgets wrapped in tap detectors.
