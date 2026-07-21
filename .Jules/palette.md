## 2026-07-21 - Adding Tooltips to Icon Buttons
**Learning:** Found that custom buttons, often built with 'GestureDetector' and 'Container' containing an 'Icon', lack tooltips (which are natively supported by 'IconButton' or explicitly added by 'Tooltip').
**Action:** Wrap icon-only buttons with 'Tooltip' to ensure hover states and accessibility labels, or replace them with 'IconButton' using 'constraints' to preserve layout spacing.
