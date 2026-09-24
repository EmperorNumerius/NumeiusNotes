## 2024-05-20 - Adding Tooltip to Note Options Icon
**Learning:** Found a missing tooltip on an icon-only button for "Note options" (`Icons.more_horiz_rounded`) within the `home_page.dart` grid items. The button previously used a raw `GestureDetector`.
**Action:** Wrapped the `GestureDetector` with a `Tooltip(message: 'Note options')` to improve accessibility for screen readers and mouse users. Re-ran layout tests to ensure no flex overflow occurred. Also fixed an existing `RenderFlex` overflow by wrapping the NumeiusNotes text in the sidebar with an `Expanded` widget.
