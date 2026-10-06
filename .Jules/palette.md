## 2024-10-06 - Responsive Sidebar App Title
**Learning:** Fixed width layout combined with static text elements placed next to fixed-width icons causes RenderFlex overflow errors on narrow viewports.
**Action:** Always wrap static text components next to fixed-width elements (e.g. icons) with `Expanded` and `TextOverflow.ellipsis` to allow them to scale down appropriately.
