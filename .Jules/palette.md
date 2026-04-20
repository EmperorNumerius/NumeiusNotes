## 2024-04-20 - [Add confirmation dialogs for destructive actions]
**Learning:** [Users expect confirmation before permanently deleting resources like folders or documents to avoid accidental data loss. This was a critical UX/accessibility insight.]
**Action:** [Added `showDialog` with an `AlertDialog` confirming deletion before calling the actual delete function. Reusable pattern for other destructive interactions in the app.]
