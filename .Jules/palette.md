## 2023-11-25 - [Accessible Icon Buttons]
**Learning:** Custom icon buttons built with `GestureDetector` and `Container` lack accessibility labels and visual focus states, making them difficult for screen reader and keyboard users.
**Action:** When building custom icon buttons, wrap them with `Tooltip` + `Material` + `InkWell` to ensure they provide an accessible label, a keyboard focus ring, and visual feedback on interaction.
