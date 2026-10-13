## 2025-05-18 - Tooltip for Action Menus on Notes
**Learning:** Found an accessibility issue where `GestureDetector` used for "more options" (three dots menu) on notes lacks screen reader context and hover tooltip, which is a standard pattern in lists. Using `Tooltip` wrapping `GestureDetector` preserves specific layouts that might overflow with `IconButton`.
**Action:** Replace unlabelled `GestureDetector` with an accessible `Tooltip` wrapping the element.
