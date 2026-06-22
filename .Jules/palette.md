## 2024-05-24 - Accessibility improvements
**Learning:** Found several icon-only buttons (`IconButton`, `GestureDetector` with `Icon`) missing tooltips/accessibility labels across the app (e.g. `home_page.dart`, `transcription_panel.dart`). This makes it hard for screen readers to convey the button intent.
**Action:** Always wrap icon-only interactive elements in `Tooltip` widgets to improve discoverability and accessibility. I will select one component to fix today.
