## 2024-05-24 - Custom Button Accessibility
**Learning:** In this Flutter application, custom icon-only components like `_CircleButton` (found in `AudioToolbar`) initially lacked built-in accessibility semantics (like ARIA equivalents) and standard touch feedback mechanisms. This pattern required manual implementation.
**Action:** Always wrap custom icon-only interactive widgets with `Tooltip` (to provide screen reader labels and visual context) and replace bare `GestureDetector`s with `Material` > `InkWell` (to provide standard ripple feedback and keyboard focus support).
