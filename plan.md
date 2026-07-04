1. **Add `Tooltip` wrapper around Tab "Close" icon button in `TabManager` (`lib/widgets/tab_manager.dart`)**
   - The close icon on tabs currently has no hover feedback or accessible label. I will wrap the `GestureDetector` for the close button in a `Tooltip(message: 'Close tab', ...)`.
2. **Add `Tooltip` wrapper around Code Block "Clear output" icon button in `CodeBlockWidget` (`lib/widgets/code_block.dart`)**
   - The close icon to hide the terminal output doesn't have a tooltip.
3. **Change Tab "Add Tab" button from `InkWell` directly inside `Material` to also have a tooltip**
   - In `TabManager`, the "Add tab" button is an `InkWell` inside a `Material`. Add a `Tooltip` with message 'New tab'.
4. **Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.**
   - Run `dart format`, tests, and `flutter analyze`.
5. **Submit the PR**
   - Describe UX improvements for tab and code block tooltips.
