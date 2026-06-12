## 2024-06-12 - Missing Tooltips in PDF Viewer Toolbar
**Learning:** In the PDF Viewer toolbar, the Undo and Redo buttons were created manually using `GestureDetector` and `Icon` without corresponding `Tooltip` widgets, unlike other custom toolbars (like in `CanvasPage`) which use a standardized `_iconBtn` helper that guarantees tooltips are present.
**Action:** When building custom icon-only action toolbars in Flutter, always ensure elements are wrapped in `Tooltip` widgets to improve discoverability and accessibility, or adopt a shared helper widget to prevent omissions.
