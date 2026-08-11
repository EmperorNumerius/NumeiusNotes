
## 2026-08-11 - Replaced GestureDetector with IconButton in note card for a11y
**Learning:** In Flutter, wrapping an Icon with GestureDetector for tap events lacks built-in semantic/accessibility features like tooltips which are essential for accessibility.
**Action:** Use standard IconButton which natively supports the tooltip property for screen readers and desktop hovers, ensuring proper constraints and padding are adjusted so layout remains unaffected.
