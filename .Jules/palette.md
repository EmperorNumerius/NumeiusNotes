## 2024-11-11 - Fixed RenderFlex overflow by wrapping text in Expanded
**Learning:** Found an unconstrained `Text` widget displaying the app title causing a `RenderFlex` overflow during tests with narrow screens. This confirms that even seemingly static or short text elements need `Expanded` or `Flexible` wrappers if they sit in a bounded, tight parent row when screen constraints might shrink.
**Action:** Wrapped the `Text` in `Expanded` and added `overflow: TextOverflow.ellipsis` to fix the test overflow issue and ensure better layout stability under varying conditions.
