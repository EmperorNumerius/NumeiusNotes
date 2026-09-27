## YYYY-MM-DD - [Title]
**Learning:** Found multiple instances of `GestureDetector` used for icon buttons in `lib/widgets/pdf_viewer_page.dart` (like undo/redo) without semantic labels. This is a common pattern in custom toolbars where `IconButton` is avoided for tighter layout control, but it sacrifices accessibility.
**Action:** Wrap these `GestureDetector` instances in `Tooltip` widgets, which inherently provide semantic labeling for screen readers while adding visual hover context.

## 2024-10-27 - Strict Analyzer Settings and Ignored Code
**Learning:** This project's CI uses strict analyzer settings where `info` severity issues (like `deprecated_member_use` or `curly_braces_in_flow_control_structures`) cause build failures. A previous PR failed because it didn't fix unrelated pre-existing linting issues in `ai_settings_dialog.dart`, `calculator_block.dart`, and `tab_manager.dart`.
**Action:** When working on a repo with strict analyzer rules, fix or explicitly `// ignore:` any new issues reported by `flutter analyze` across the entire codebase to ensure CI passes, even if they are outside the immediately modified files.

## 2024-10-27 - Handling RenderFlex Overflows in Constrained UI
**Learning:** Adding a `Tooltip` or changing standard interaction elements (like `GestureDetector` to `IconButton`) can sometimes introduce unexpected layout constraints. More critically, when modifying static text elements in a layout (like a sidebar) next to an icon, if the string isn't constrained or wrapped in an `Expanded` widget, narrow viewpoints or tests can trigger a `RenderFlex` overflow (e.g. `RenderFlex overflowed by 49 pixels on the right`).
**Action:** Always verify that static text elements in tight horizontal layouts (like `Row` or `Flex` components) are wrapped with `Expanded` or `Flexible` and use `overflow: TextOverflow.ellipsis` to gracefully handle space constraints and prevent UI crashes during testing or on smaller screens.
