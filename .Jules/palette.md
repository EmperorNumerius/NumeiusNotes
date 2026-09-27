## 2024-10-27 - Icon Accessibility in PDF Viewer
**Learning:** Found multiple instances of `GestureDetector` used for icon buttons in `lib/widgets/pdf_viewer_page.dart` (like undo/redo) without semantic labels. This is a common pattern in custom toolbars where `IconButton` is avoided for tighter layout control, but it sacrifices accessibility.
**Action:** Wrap these `GestureDetector` instances in `Tooltip` widgets, which inherently provide semantic labeling for screen readers while adding visual hover context.
