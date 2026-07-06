## 2024-07-06 - Tooltip & MouseRegion for Desktop Web
**Learning:** In desktop/web environments with Flutter, icon-only interactive elements wrapped in `GestureDetector` often lack hover cursor states and textual explanations, which hinders accessibility. Adding a `MouseRegion(cursor: SystemMouseCursors.click)` along with a `Tooltip` wrapper correctly signals interactivity while improving screen reader and mouse navigation.
**Action:** Consistently wrap `GestureDetector` or similar raw hit-test targets with `MouseRegion` and `Tooltip` when rendering icon-only actions for better UX.
