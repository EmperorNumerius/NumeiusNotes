## 2024-05-19 - Replace more_horiz_rounded GestureDetector with IconButton
**Learning:** Replaced `GestureDetector` with `IconButton` for the `more_horiz_rounded` icon in the note card `home_page.dart`. This adds better accessibility support natively through `IconButton` (built-in tooltip and semantics).
**Action:** Use `IconButton` for generic icon-only buttons for out-of-the-box accessibility where sizing permits. Ensure the `onPressed` callback is hooked up instead of `onTap`.
