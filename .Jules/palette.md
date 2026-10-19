## 2024-05-24 - Accessibility improvements on TabManager and Home Page
**Learning:** Found that custom layout constraints and the use of basic interaction widgets (GestureDetector/InkWell) missed out on basic a11y properties like semantic roles and tooltips. Also noticed some unconstrained Text widgets caused RenderFlex errors when screen size shrinks.
**Action:** Replace `GestureDetector`/`InkWell` with `IconButton` or wrapping them in `Tooltip` where spacing is tight. Add `Expanded` or `Flexible` to Text widgets next to icons when unconstrained size issues might arise.
