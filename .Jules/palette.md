## 2024-05-24 - Missing Tooltip on Icon-Only Breadcrumb Navigation
**Learning:** Icon-only navigation buttons in breadcrumbs require explicit `Tooltip` wrappers for accessibility. While `InkWell` provides visual touch feedback, it lacks context for screen readers and offers no hover tooltips, creating barriers for keyboard and screen reader users.
**Action:** Always wrap custom `InkWell` or `GestureDetector` based icon-only buttons with a `Tooltip` widget providing a descriptive `message` for the navigation action.
