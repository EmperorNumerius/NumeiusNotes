## 2024-04-23 - Confirmation Dialogs for Destructive Actions
**Learning:** Destructive actions like deleting folders or notes should be preceded by a confirmation dialog to prevent accidental data loss. This was found lacking in the context menus of `home_page.dart`. A simple `showDialog` with an `AlertDialog` provides a familiar and accessible confirmation flow.
**Action:** Always wrap destructive operations (`deleteFolder`, `deleteDocument`, etc.) in a user confirmation prompt rather than executing them immediately on tap.
