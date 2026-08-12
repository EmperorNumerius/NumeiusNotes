
## 2024-05-24 - Accessible tooltips with IconButton
**Learning:** Using `IconButton` instead of wrapping an `Icon` with a `GestureDetector` naturally provides an accessible tooltip and appropriate semantic ARIA-like label for screen readers on hover, natively resolving a widespread accessibility gap in custom Flutter widgets without needing to manually wrap components in a `Tooltip`.
**Action:** When creating icon-only interactive elements in Flutter, prefer `IconButton` (allowing it to use default padding and constraints to provide the standard 48x48 accessible touch target) to automatically receive built-in tooltip accessibility rather than building custom `GestureDetector` wrappers.
