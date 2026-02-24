import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:notes_app/models/content_block.dart';

/// Widget to render and edit LaTeX equations.
class LatexBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback onChanged;

  const LatexBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<LatexBlockWidget> createState() => _LatexBlockWidgetState();
}

class _LatexBlockWidgetState extends State<LatexBlockWidget> {
  bool _isEditing = false;
  late TextEditingController _editCtrl;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.block.content);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C3AED).withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.functions_rounded,
                  size: 14, color: const Color(0xFF7C3AED).withAlpha(180)),
              const SizedBox(width: 6),
              Text(
                'LaTeX',
                style: TextStyle(
                  color: const Color(0xFF7C3AED).withAlpha(180),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Copy
              _actionButton(
                icon: Icons.copy_rounded,
                tooltip: 'Copy LaTeX',
                onTap: () {
                  // Copy to clipboard — simplified for now
                },
              ),
              const SizedBox(width: 4),
              // Edit toggle
              _actionButton(
                icon: _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                tooltip: _isEditing ? 'Done' : 'Edit',
                onTap: () {
                  if (_isEditing) {
                    widget.block.content = _editCtrl.text;
                    widget.onChanged();
                  }
                  setState(() => _isEditing = !_isEditing);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rendered LaTeX or editor
          if (_isEditing)
            TextField(
              controller: _editCtrl,
              maxLines: null,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Courier New',
              ),
              decoration: InputDecoration(
                hintText: r'Enter LaTeX (e.g. E = mc^2)',
                hintStyle: TextStyle(color: Colors.white.withAlpha(30)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.white.withAlpha(15)),
                ),
                filled: true,
                fillColor: Colors.white.withAlpha(5),
                contentPadding: const EdgeInsets.all(12),
              ),
            )
          else
            Center(
              child: widget.block.content.isEmpty
                  ? Text('Tap edit to enter LaTeX',
                      style: TextStyle(
                          color: Colors.white.withAlpha(30), fontSize: 13))
                  : Math.tex(
                      widget.block.content,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                      onErrorFallback: (err) => Text(
                        'Invalid LaTeX: ${err.message}',
                        style: const TextStyle(
                            color: Color(0xFFFF6B6B), fontSize: 12),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: Colors.white.withAlpha(100)),
        ),
      ),
    );
  }
}
