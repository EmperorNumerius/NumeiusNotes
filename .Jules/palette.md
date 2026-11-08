## 2024-05-28 - Tooltips in Custom Grid Layouts
**Learning:** In constrained custom layouts like dense grids or tab managers, wrapping interaction widgets like GestureDetector/InkWell with Tooltip is preferred over using IconButton, to avoid RenderFlex overflow errors caused by default constraints.
**Action:** Always test Tooltips in narrow constraints and wrap existing interaction targets when working in dense grid/tab UI components.
