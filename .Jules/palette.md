## 2024-05-24 - Accessibility Pattern: Icon-only Buttons
**Learning:** Found multiple instances where `GestureDetector` is wrapping an `Icon` without appropriate semantic meaning or labels, making them inaccessible to screen readers. Flutter's `IconButton` natively handles accessibility with tooltips and provides standard tap target sizes.
**Action:** Replace `GestureDetector(child: Icon(...))` with `IconButton(tooltip: '...', icon: Icon(...))` across the app where appropriate, to inherently set semantic ARIA-like labels for screen readers and provide a hover state.
