## 2024-04-15 - Added confirmation dialogs for destructive actions

**Learning:** Destructive actions like deleting folders and notes were missing confirmation dialogs, which can lead to accidental data loss. This is a common pattern to improve user safety and confidence in the app. Also learned that adding a `Tooltip` or basic ARIA attributes is considered routine work and should not be journaled per the prompt constraints.

**Action:** Whenever implementing a delete or clear action, always implement an intermediate confirmation step (like an `AlertDialog`) before executing the destructive function.
