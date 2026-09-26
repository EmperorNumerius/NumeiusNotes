## 2026-09-26 - Prevent text overflow in App Title
**Learning:** Fixed a layout overflow issue where app title in fixed-width sidebar caused RenderFlex overflow when text scaling increased or in very compact layouts.
**Action:** Replaced static `Text` with `Expanded(child: Text(..., overflow: TextOverflow.ellipsis))` to guarantee no rendering overflow.
## 2026-09-26 - Improve Tab Close Button Accessibility
**Learning:** Replaced `GestureDetector` wrapped around an `Icon` with an `IconButton` in the compact `TabManager` component. Overrode default padding and constrained the target size with `BoxConstraints(minWidth: 16, minHeight: 16)` to ensure it remained visually integrated while providing a built-in tooltip, proper keyboard focus, and semantics without breaking layout.
**Action:** When replacing touch targets with `IconButton` in constrained UI areas, always manage `padding` and `constraints` explicitly.
