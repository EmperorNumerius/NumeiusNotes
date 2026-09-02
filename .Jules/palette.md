## 2024-09-02 - Accessible Icon Buttons

**Learning:** When replacing `GestureDetector` with `IconButton` for small icons (like note options menus) to improve accessibility (adding hover states, focus states, and ARIA-like labels), Flutter's default `IconButton` dimensions and padding can cause layout overflows if not properly constrained, especially within strict constraints like `home_page.dart`'s note cards.

**Action:** When swapping a `GestureDetector` to an `IconButton` in constrained UI components, always set `padding: EdgeInsets.zero` and explicitly use `BoxConstraints(minWidth: X, minHeight: Y)` (where X and Y reflect the original icon's rough size, like 24x24) to maintain the layout without triggering `RenderFlex` overflows, while still providing an adequately sized tap target for accessibility.
