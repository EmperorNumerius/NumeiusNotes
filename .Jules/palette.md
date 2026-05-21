## 2023-10-27 - Confirm Before Delete Pattern
**Learning:** Adding a confirmation dialog using an async helper method ensures users don't accidentally delete data. Stacking modals (like bottom sheets calling dialogs) requires popping the initial modal first to prevent unexpected layout states.
**Action:** Use an async helper method `_confirmDelete` and ensure `Navigator.pop(ctx)` is called on the bottom sheet before showing the confirmation dialog.
