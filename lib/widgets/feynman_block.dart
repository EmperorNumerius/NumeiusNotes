import 'package:flutter/material.dart';
import 'package:notes_app/widgets/content_blocks/base_block_widget.dart';

class FeynmanBlockWidget extends BaseBlockWidget {
  const FeynmanBlockWidget({
    super.key,
    required super.block,
    super.onChanged,
    super.onDelete,
    super.onDragStart,
    super.onDragUpdate,
    super.onDragEnd,
    super.isDragging,
  });

  @override
  State<FeynmanBlockWidget> createState() => _FeynmanBlockWidgetState();
}

class _FeynmanBlockWidgetState extends BaseBlockState<FeynmanBlockWidget> {
  late TextEditingController _conceptController;
  late TextEditingController _explanationController;
  late TextEditingController _analogyController;
  late TextEditingController _gapsController;

  @override
  void initState() {
    super.initState();
    _conceptController = TextEditingController(text: widget.block.content);
    _explanationController = TextEditingController(text: widget.block.metadata['explanation'] ?? '');
    _analogyController = TextEditingController(text: widget.block.metadata['analogy'] ?? '');
    _gapsController = TextEditingController(text: widget.block.metadata['gaps'] ?? '');
  }

  @override
  void didUpdateWidget(covariant FeynmanBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _conceptController.text = widget.block.content;
      _explanationController.text = widget.block.metadata['explanation'] ?? '';
      _analogyController.text = widget.block.metadata['analogy'] ?? '';
      _gapsController.text = widget.block.metadata['gaps'] ?? '';
    }
  }

  @override
  void dispose() {
    _conceptController.dispose();
    _explanationController.dispose();
    _analogyController.dispose();
    _gapsController.dispose();
    super.dispose();
  }

  void _update() {
    widget.block.content = _conceptController.text;
    widget.block.metadata['explanation'] = _explanationController.text;
    widget.block.metadata['analogy'] = _analogyController.text;
    widget.block.metadata['gaps'] = _gapsController.text;
    widget.onChanged?.call();
  }

  @override
  Color get backgroundColor => const Color(0xFF2D1B4E); // Deep purple/indigo

  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _conceptController,
            label: 'Concept',
            hint: 'What concept are you learning?',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _explanationController,
            label: 'Explanation',
            hint: 'Explain it like you are teaching it to someone else...',
            minLines: 3,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _analogyController,
            label: 'Simple Terms / Analogy',
            hint: 'Use simple language or an analogy...',
            minLines: 2,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _gapsController,
            label: 'Gaps / Questions',
            hint: 'What part do you not understand yet?',
            minLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int minLines = 1,
    TextStyle? style,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withAlpha(100),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: null,
          minLines: minLines,
          onChanged: (_) => _update(),
          style: style ?? const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withAlpha(30)),
            filled: true,
            fillColor: Colors.black.withAlpha(40),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
