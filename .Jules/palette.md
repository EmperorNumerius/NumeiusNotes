## 2024-05-18 - Tooltips for Custom Icon Actions
**Learning:** Icon-only buttons within constrained custom layouts like note cards can cause RenderFlex issues if simply replaced by `IconButton` which has standard padding/sizing constraints.
**Action:** Prefer wrapping existing interaction widgets like `GestureDetector` or `InkWell` with a `Tooltip` widget instead of swapping to `IconButton` in dense UI layouts to improve accessibility without breaking layout sizes.
