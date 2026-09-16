
## 2024-05-24 - IconButton sizing in constrained layouts
**Learning:** When replacing GesturesDetectors with IconButtons in dense spaces like TabManager, default paddings cause RenderFlex overflow, but overriding constraints is required to keep proper hit targets.
**Action:** Use BoxConstraints(minWidth: 24, minHeight: 24) when overriding IconButton padding to zero.
