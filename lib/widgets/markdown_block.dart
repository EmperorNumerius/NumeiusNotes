import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:notes_app/models/content_block.dart';

/// Markdown block with editing + preview modes and a lightweight formatting bar.
class MarkdownBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback? onChanged;

  const MarkdownBlockWidget({
    super.key,
    required this.block,
    this.onChanged,
  });

  @override
  State<MarkdownBlockWidget> createState() => _MarkdownBlockWidgetState();
}

class _MarkdownBlockWidgetState extends State<MarkdownBlockWidget> {
  late TextEditingController _controller;
  bool _isEditing = true;
  final ScrollController _previewScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content);
    _isEditing = widget.block.content.isEmpty;
  }

  @override
  void didUpdateWidget(covariant MarkdownBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _controller.text = widget.block.content;
      _isEditing = widget.block.content.isEmpty;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _previewScrollController.dispose();
    super.dispose();
  }

  void _updateContent(String value) {
    widget.block.content = value;
    widget.onChanged?.call();
  }

  void _insertToken(String prefix, {String? suffix, String placeholder = 'text'}) {
    final selection = _controller.selection;
    final selectedText = selection.isValid
        ? _controller.text.substring(selection.start, selection.end)
        : '';
    final hasSelection = selectedText.isNotEmpty;
    final replacement = '$prefix${hasSelection ? selectedText : placeholder}${suffix ?? ''}';

    final nextText = _controller.text.replaceRange(
      selection.start,
      selection.end,
      replacement,
    );

    final caretOffset = selection.start + replacement.length;
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: caretOffset),
    );
    _updateContent(nextText);
  }

  void _insertMultiline(String snippet) {
    final selection = _controller.selection;
    final nextText = _controller.text.replaceRange(
      selection.start,
      selection.end,
      snippet,
    );
    final caretOffset = selection.start + snippet.length;
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: caretOffset),
    );
    _updateContent(nextText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101626),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B).withAlpha(55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.markdown_rounded,
                  size: 14, color: const Color(0xFFFF6B6B).withAlpha(190)),
              const SizedBox(width: 6),
              Text(
                'Markdown',
                style: TextStyle(
                  color: const Color(0xFFFF6B6B).withAlpha(190),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _tabButton('Edit', _isEditing, () => setState(() => _isEditing = true)),
              const SizedBox(width: 4),
              _tabButton('Preview', !_isEditing, () => setState(() => _isEditing = false)),
            ],
          ),
          const SizedBox(height: 10),
          _buildToolbar(),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 140),
            child: _isEditing ? _buildEditor() : _buildPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _toolButton(Icons.format_bold_rounded, 'Bold', () => _insertToken('**', suffix: '**')),
        _toolButton(Icons.format_italic_rounded, 'Italic', () => _insertToken('_', suffix: '_')),
        _toolButton(Icons.title_rounded, 'Heading', () => _insertToken('## ', placeholder: 'Heading')),
        _toolButton(Icons.check_box_rounded, 'Checkbox', () => _insertToken('- [ ] ', placeholder: 'Task')),
        _toolButton(Icons.code_rounded, 'Code fence', () => _insertMultiline('```\ncode\n```')),
      ],
    );
  }

  Widget _buildEditor() {
    return TextField(
      key: const ValueKey('markdown-editor'),
      controller: _controller,
      maxLines: null,
      minLines: 7,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        height: 1.45,
        fontFamily: 'Courier New',
      ),
      decoration: InputDecoration(
        hintText: '# Start writing markdown...\n\n- bullets\n- checkboxes\n- code blocks',
        hintStyle: TextStyle(color: Colors.white.withAlpha(32)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withAlpha(14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withAlpha(14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: const Color(0xFFFF6B6B).withAlpha(85)),
        ),
        filled: true,
        fillColor: Colors.white.withAlpha(3),
        contentPadding: const EdgeInsets.all(12),
      ),
      onChanged: _updateContent,
    );
  }

  Widget _buildPreview() {
    final source = _controller.text.trim();
    if (source.isEmpty) {
      return Container(
        key: const ValueKey('markdown-empty-preview'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'Nothing to preview yet. Add Markdown in edit mode.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withAlpha(45), fontSize: 12),
        ),
      );
    }

    return Container(
      key: const ValueKey('markdown-preview'),
      constraints: const BoxConstraints(maxHeight: 340),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Markdown(
        data: source,
        controller: _previewScrollController,
        shrinkWrap: true,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
          h1: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
          h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          code: const TextStyle(
            color: Color(0xFFFFD8A8),
            fontFamily: 'Courier New',
            backgroundColor: Color(0x44333344),
          ),
          codeblockDecoration: BoxDecoration(
            color: const Color(0xFF1B2236),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
          blockquoteDecoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(4),
            border: Border(left: BorderSide(color: const Color(0xFFFF6B6B).withAlpha(130), width: 3)),
          ),
          listBullet: const TextStyle(color: Colors.white70),
          checkbox: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white.withAlpha(10)),
          ),
          child: Icon(icon, size: 14, color: Colors.white.withAlpha(180)),
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF6B6B).withAlpha(35) : Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: active ? const Color(0xFFFF6B6B).withAlpha(110) : Colors.white.withAlpha(16),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFFFF6B6B) : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
