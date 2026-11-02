## 2023-11-02 - Added Tooltip to icon buttons
**Learning:** Adding Tooltips significantly improves accessibility and adds micro-UX delight for icon-only buttons like the note more options dots or tab add/close without breaking UI layout constraints, while wrapping elements like `Expanded` ensures no flex overflow errors happen in narrow views.
**Action:** Always wrap `InkWell` or `GestureDetector` that display icon-only actions with `Tooltip` where `IconButton` is not possible or breaks padding constraints. Use `Expanded` correctly to prevent narrow viewport overflows.
