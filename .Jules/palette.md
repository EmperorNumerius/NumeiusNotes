## 2024-10-24 - Delete Confirmation Dialog
**Learning:** Destructive actions without confirmation are a common UX pitfall. Adding a simple confirmation dialog prevents accidental data loss and improves user trust. Also, when adding layout components like dialogs, be aware of potential RenderFlex overflows in tests that use default screen sizes.
**Action:** Always wrap destructive actions (like deletions) with a confirmation dialog. Mock screen sizes in tests to avoid layout issues when structural changes are introduced.
