## 2024-05-18 - Added confirmation dialogs for destructive actions
**Learning:** Added an explicit confirmation step before permanently deleting folders and notes prevents accidental data loss, which is a major pain point for users. It also provides a clear visual signal that the action is irreversible. The layout overflow issue was also resolved by wrapping the title in an `Expanded` widget.
**Action:** Always include confirmation dialogs for destructive actions like deleting content or data.
