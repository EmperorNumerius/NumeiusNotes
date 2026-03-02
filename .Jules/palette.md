## 2026-03-02 - Accessible Icon-Only Buttons
**Learning:** Custom icon-only buttons (like `_CircleButton`) lack accessibility labels, keyboard focus, and visual feedback when implemented with `GestureDetector` and `Container`.
**Action:** Always utilize `Tooltip` wrapping `InkWell` (within `Material`) for custom icon-only buttons to ensure proper accessibility labels, keyboard focus, and visual ripple feedback while maintaining custom styling via `Ink`.
