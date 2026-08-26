## 2026-08-26 - Accessible Icon-only Buttons
**Learning:** Found a pattern where icon-only buttons were implemented using GestureDetector, stripping them of native hover states, keyboard focusability, and ARIA-like screen reader labels. Flutter's IconButton natively provides all of these accessibility features.
**Action:** When replacing GestureDetector with IconButton in constrained layouts, override padding to EdgeInsets.zero and use BoxConstraints to prevent layout overflows while maintaining minimum accessible tap targets.
