## 2024-06-25 - Icon-Only Buttons Accessibility

**Learning:** When custom UI widgets in Flutter implement icon-only buttons via `GestureDetector` wrapped around a `Container` or `AnimatedContainer`, they often lack accessibility (a11y) considerations like standard touch target sizes, focus rings, hover states, and semantic ARIA-like labels for screen readers.

**Action:** Prefer replacing these custom `GestureDetector` implementations with Flutter's built-in `IconButton` widget. Setting `padding: EdgeInsets.zero` and `constraints: const BoxConstraints()` on the `IconButton` alongside supplying the `icon` argument as the original container structure preserves the exact visual design while adding proper a11y support via the `tooltip` property natively.
