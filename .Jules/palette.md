## 2024-11-10 - Tooltips for icon-only buttons
**Learning:** Found multiple instances where `GestureDetector` or `InkWell` wrapping an icon lacked `Tooltip` semantics for accessibility and usability. Replacing them with `IconButton` natively supports tooltips and accessible touch targets. However, `IconButton` can cause `RenderFlex` overflow errors in tight or specific layouts, so we might need to use `Tooltip` explicitly wrapping the interactive element.
**Action:** Always wrap icon-only buttons in `Tooltip` widgets, or prefer using `IconButton(tooltip: "...")` if the layout allows.
