## 2024-05-24 - Add Confirmation Dialog for Destructive Actions
**Learning:** Immediate deletion of items (folders/notes) without confirmation is a poor UX practice, leading to potential accidental data loss.
**Action:** Always wrap destructive operations (like `deleteDocument` or `deleteFolder`) with a confirmation dialog (e.g., `AlertDialog`) clearly explaining the consequences before execution.
