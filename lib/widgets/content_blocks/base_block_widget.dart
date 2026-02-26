import 'package:flutter/material.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/widgets/draggable_block_shell.dart';

/// Base class for all content block widgets.
/// Encapsulates the DraggableBlockShell and common behavior.
abstract class BaseBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback? onChanged;
  final VoidCallback? onDelete;
  final GestureDragStartCallback? onDragStart;
  final GestureDragUpdateCallback? onDragUpdate;
  final GestureDragEndCallback? onDragEnd;
  final bool isDragging;

  const BaseBlockWidget({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.isDragging = false,
  });
}

/// Base state class for content blocks.
/// Subclasses should implement [buildContent] to provide the specific UI.
abstract class BaseBlockState<T extends BaseBlockWidget> extends State<T> {
  /// Override to provide the content widget inside the block shell.
  Widget buildContent(BuildContext context);

  /// Optional override for shell background color.
  Color get backgroundColor => const Color(0xFF141428);

  @override
  Widget build(BuildContext context) {
    return DraggableBlockShell(
      block: widget.block,
      isDragging: widget.isDragging,
      content: buildContent(context),
      onDelete: widget.onDelete ?? () {},
      onDragStart: widget.onDragStart ?? (_) {},
      onDragUpdate: widget.onDragUpdate ?? (_) {},
      onDragEnd: widget.onDragEnd ?? (_) {},
      backgroundColor: backgroundColor,
    );
  }
}
