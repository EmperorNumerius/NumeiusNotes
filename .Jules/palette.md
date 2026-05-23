## 2024-05-18 - RenderFlex Overflow with NumeiusNotes Title
**Learning:** In widget tests for narrow-viewport scenarios, horizontal lists with static width elements alongside text elements can cause `RenderFlex` overflow errors.
**Action:** Wrapping text elements in `Expanded` and using `overflow: TextOverflow.ellipsis` gracefully handles viewport constraints and prevents rendering failures in tests.
