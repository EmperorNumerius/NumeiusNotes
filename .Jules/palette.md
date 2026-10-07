## 2024-05-24 - Note Card Context Menu Accessibility
**Learning:** In Flutter grid layouts, adding standard IconButtons for context menus can cause RenderFlex overflows due to their default padding/tap targets. However, leaving them as plain Icon+GestureDetector combinations makes them invisible to screen readers and mouse users looking for tooltips.
**Action:** Always wrap plain GestureDetector-based icon buttons in a Tooltip widget in dense UI components to provide accessibility context without disrupting the layout constraints.
