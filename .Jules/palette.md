## 2024-05-15 - Accessible Tab Close Buttons
**Learning:** Using IconButton instead of GestureDetector for icon-only close buttons improves screen reader accessibility by supporting tooltips natively, but requires careful BoxConstraints to maintain compact layout.
**Action:** Always prefer IconButton with a tooltip and proper constraints for compact close actions instead of raw GestureDetectors.
