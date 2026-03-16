import 'package:flutter/material.dart';
import 'package:notes_app/models/content_block.dart';

class DraggableBlockShell extends StatelessWidget {
  const DraggableBlockShell({
    super.key,
    required this.block,
    required this.isDragging,
    required this.content,
    required this.onDelete,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.backgroundColor = const Color(0xFF141428),
  });

  final ContentBlock block;
  final bool isDragging;
  final Widget content;
  final VoidCallback onDelete;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final metadata = _blockMetadata(block.type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: block.blockWidth,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDragging
              ? metadata.color.withAlpha(160)
              : Colors.white.withAlpha(14),
          width: isDragging ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDragging
                ? metadata.color.withAlpha(30)
                : Colors.black.withAlpha(60),
            blurRadius: isDragging ? 24 : 10,
            offset: Offset(0, isDragging ? 6 : 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: onDragStart,
            onPanUpdate: onDragUpdate,
            onPanEnd: onDragEnd,
            child: _BlockHeader(
              color: metadata.color,
              icon: metadata.icon,
              label: metadata.label,
              onDelete: onDelete,
            ),
          ),
          content,
        ],
      ),
    );
  }
}

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({
    required this.color,
    required this.icon,
    required this.label,
    required this.onDelete,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(
          bottom: BorderSide(color: color.withAlpha(20)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            size: 16,
            color: Colors.white.withAlpha(50),
          ),
          const SizedBox(width: 6),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Tooltip(
            message: 'Delete block',
            child: GestureDetector(
              onTap: onDelete,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.white.withAlpha(80),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockMetadata {
  const _BlockMetadata({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;
}

_BlockMetadata _blockMetadata(ContentBlockType type) {
  switch (type) {
    case ContentBlockType.text:
      return const _BlockMetadata(
        color: Color(0xFF00D2FF),
        icon: Icons.text_fields_rounded,
        label: 'Text',
      );
    case ContentBlockType.code:
      return const _BlockMetadata(
        color: Color(0xFF51CF66),
        icon: Icons.code_rounded,
        label: 'Code',
      );
    case ContentBlockType.latex:
      return const _BlockMetadata(
        color: Color(0xFF7C3AED),
        icon: Icons.functions_rounded,
        label: 'LaTeX',
      );
    case ContentBlockType.chemistry:
      return const _BlockMetadata(
        color: Color(0xFF38D9A9),
        icon: Icons.science_rounded,
        label: 'Chemistry',
      );
    case ContentBlockType.calculator:
      return const _BlockMetadata(
        color: Color(0xFFFFAA5C),
        icon: Icons.calculate_rounded,
        label: 'Calculator',
      );
    case ContentBlockType.flashcard:
      return const _BlockMetadata(
        color: Color(0xFFFF6B9A),
        icon: Icons.style_rounded,
        label: 'Flashcard',
      );
    case ContentBlockType.markdown:
      return const _BlockMetadata(
        color: Color(0xFFFF6B6B),
        icon: Icons.article_rounded,
        label: 'Markdown',
      );
    case ContentBlockType.image:
      return const _BlockMetadata(
        color: Color(0xFF4DABF7),
        icon: Icons.image_rounded,
        label: 'Image',
      );
    case ContentBlockType.feynman:
      return const _BlockMetadata(
        color: Color(0xFFFFAA5C),
        icon: Icons.lightbulb_outline_rounded,
        label: 'Feynman',
      );
  }
}

