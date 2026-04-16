## 2024-04-16 - Add Delete Confirmation Dialogs

**Learning:** Destructive actions, such as deleting documents or folders, were taking effect immediately without confirmation in the app, which can lead to accidental data loss. While fixing this, I learned that standard Flutter UI patterns for critical actions should include an `AlertDialog` to interrupt the user flow and verify intent. Adding these dialogs improves the robustness of the UX significantly by introducing a simple, recoverable checkpoint.
**Action:** Always add a confirmation dialog (`AlertDialog` via `showDialog`) before invoking any irreversible destructive functions like `deleteDocument` or `deleteFolder`.
