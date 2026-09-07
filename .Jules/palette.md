## 2024-05-15 - IconButton Accessibility Over GestureDetector
**Learning:** Using GestureDetector for icon-only buttons removes native accessibility features (ARIA-like labels, tooltips, hover states) and decreases tap targets below accessible sizes. Native IconButton is vastly superior for UX and a11y.
**Action:** Always prefer IconButton over GestureDetector for icons unless overriding constraints completely break complex UI layouts, in which case use Tooltip and Semantics explicitly.
