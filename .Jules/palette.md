## 2026-03-16 - Added Tooltips to IconButtons
**Learning:** Icon-only buttons without tooltips lack accessibility labels and hover text, making them difficult to use for screen reader users and ambiguous for desktop users.
**Action:** Always provide a `tooltip` parameter for `IconButton` widgets or wrap icon-only gesture detectors in a `Tooltip`.
