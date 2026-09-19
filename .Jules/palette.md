## 2026-09-19 - Accessible Icon Buttons in Compact Layouts
**Learning:** Replacing GestureDetector with IconButton in dense UI requires explicit constraints (BoxConstraints) and zero padding to prevent RenderFlex overflows while preserving accessible tap targets.
**Action:** Always override padding and set explicit BoxConstraints when using IconButton in compact parent widgets.
