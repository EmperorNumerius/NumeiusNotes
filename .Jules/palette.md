## 2026-08-21 - Replaced GestureDetector with IconButton for Accessibility
**Learning:** In Flutter, replacing an icon wrapped in a GestureDetector with an IconButton not only improves the code semantics but natively provides a standard 48x48 accessible touch target and a built-in tooltip property for hover states and screen readers, ensuring better accessibility.
**Action:** Use IconButton with a tooltip rather than wrapping an Icon in a GestureDetector, while ensuring it retains default padding and constraints unless specifically required to be smaller.
