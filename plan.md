1. **Add `MouseRegion` and `Tooltip` to note options menu icon in `lib/widgets/home_page.dart`**.
   - Wrapping the `GestureDetector` of the "more options" (three dots) icon on the note cards with a `MouseRegion(cursor: SystemMouseCursors.click)` and `Tooltip(message: 'Note options')` to improve accessibility and UX for desktop users.
2. **Add `MouseRegion` and `Tooltip` to the close tab icon in `lib/widgets/tab_manager.dart`**.
   - Wrapping the `GestureDetector` of the tab close icon with a `MouseRegion(cursor: SystemMouseCursors.click)` and `Tooltip(message: 'Close tab')` to improve clarity.
3. **Run code format (`dart format lib/widgets/home_page.dart lib/widgets/tab_manager.dart`) and ensure no regressions.**
4. **Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.**
5. **Submit the PR**
