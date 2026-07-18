## 2024-05-15 - Missing Tooltips on Icon-Only Buttons
**Learning:** Reusable custom UI components like GestureDetector wrapping an Icon are missing accessibility attributes like ARIA labels and hover states, leading to poor UX for screen readers and missing tooltips.
**Action:** Replaced GestureDetector around Icons with native IconButton widgets with proper constraints and tooltip arguments to add native screen reader labels and tooltips seamlessly.
