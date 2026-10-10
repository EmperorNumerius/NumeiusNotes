## 2024-10-10 - Tab Manager Interaction
**Learning:** The close tab icon in TabManager uses a bare GestureDetector which produces no visual hover state or tooltip. Upgrading it to an IconButton or wrapping in Tooltip significantly improves discoverability.
**Action:** Replaced bare GestureDetector with IconButton (with BoxConstraints(minWidth: 24, minHeight: 24) to maintain layout) and proper tooltip in TabManager.
