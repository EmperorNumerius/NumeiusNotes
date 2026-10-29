
## 2023-10-29 - Fixed Sidebar Overflow
**Learning:** Hard-coded text widgets in sidebars can overflow easily on smaller viewports.
**Action:** Wrap text widgets in `Expanded` and use `TextOverflow.ellipsis`.
## 2023-10-29 - Ignore Deprecated Warnings
**Learning:** Dart automatically updates code via `dart fix` which caused some `value` fields on `DropdownButtonFormField` to be incorrectly transformed. Also, sometimes deprecated properties like `onReorder` are still needed if the newer `onReorderItem` doesn't exist.
**Action:** Revert incorrect automatic updates, and add `// ignore: deprecated_member_use` explicitly.
