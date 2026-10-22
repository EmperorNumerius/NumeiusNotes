## 2024-05-18 - Fix TextOverflow on HomePage Layouts
**Learning:** Hardcoding static text strings (like NumeiusNotes) inside small Row containers causes layout RenderFlex overflows on compact viewports (e.g. mobile tests, resize events), which leads to failing widget tests.
**Action:** Always wrap such text components in Expanded or Flexible with an appropriate overflow: TextOverflow.ellipsis to ensure flexible sizing and prevent layout breaking.
