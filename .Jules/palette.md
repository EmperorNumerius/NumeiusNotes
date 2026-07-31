## 2024-07-31 - Tooltips for icon buttons

**Learning:** When using icon-only buttons for actions like note menus or closing tabs, adding a Tooltip improves accessibility by providing a label for screen readers and helpful text on hover. Using `IconButton` provides this inherently, but if replacing `GestureDetector` wrapped around an `Icon`, we need to set `padding: EdgeInsets.zero` and `constraints: const BoxConstraints()` to prevent layout shifts. In cases where we still want a `GestureDetector`, we can wrap it in a `Tooltip`.

**Action:** Update icon-only `GestureDetector` buttons to use `IconButton` with `padding` and `constraints`, or wrap them in `Tooltip` widgets to ensure they have accessible labels.
