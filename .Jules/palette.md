## 2024-05-01 - IconButton Built-in Accessibility
**Learning:** IconButton provides built-in tooltips, hover states, and semantic ARIA-like labels. This is superior and more concise than wrapping an InkWell/GestureDetector with a Tooltip widget, while naturally fulfilling accessibility requirements.
**Action:** Default to IconButton with BoxConstraints overrides for custom-sized interactive icon areas instead of GestureDetector.
