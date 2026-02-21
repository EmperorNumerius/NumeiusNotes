import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/services/code_runner_service.dart';

/// Jupyter-style code block with syntax highlighting and execution.
class CodeBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDelete;

  const CodeBlockWidget({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  late TextEditingController _controller;
  bool _isRunning = false;
  bool _showOutput = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content);
    _showOutput = widget.block.output.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runCode() async {
    setState(() {
      _isRunning = true;
      _showOutput = true;
    });

    final result = await CodeRunnerService.execute(
      _controller.text,
      widget.block.language,
    );

    setState(() {
      _isRunning = false;
      widget.block.output =
          result.stderr.isNotEmpty ? '${result.stdout}\n⚠ ${result.stderr}' : result.stdout;
    });
    widget.onChanged?.call(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF252540),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Language indicator dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.block.language == 'python'
                        ? const Color(0xFF3776AB)
                        : const Color(0xFF00599C),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Language dropdown
                DropdownButton<String>(
                  value: widget.block.language,
                  dropdownColor: const Color(0xFF252540),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  underline: const SizedBox(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'python', child: Text('Python')),
                    DropdownMenuItem(value: 'cpp', child: Text('C++')),
                    DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => widget.block.language = v);
                      widget.onChanged?.call(_controller.text);
                    }
                  },
                ),
                const Spacer(),
                // Run button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: _isRunning ? null : _runCode,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isRunning
                            ? Colors.white10
                            : const Color(0xFF51CF66).withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isRunning
                              ? Colors.white12
                              : const Color(0xFF51CF66).withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isRunning)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white38,
                              ),
                            )
                          else
                            const Icon(Icons.play_arrow,
                                size: 14, color: Color(0xFF51CF66)),
                          const SizedBox(width: 4),
                          Text(
                            _isRunning ? 'Running...' : 'Run',
                            style: TextStyle(
                              fontSize: 11,
                              color: _isRunning
                                  ? Colors.white38
                                  : const Color(0xFF51CF66),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.close, size: 16, color: Colors.white24),
                ),
              ],
            ),
          ),
          // Code area
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: _isEditing
                ? Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      autofocus: true,
                      onChanged: (v) => widget.onChanged?.call(v),
                      onTapOutside: (_) =>
                          setState(() => _isEditing = false),
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 13,
                        color: Colors.white,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter ${widget.block.language} code...',
                        hintStyle: TextStyle(color: Colors.white.withAlpha(40)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  )
                : Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    width: double.infinity,
                    child: _controller.text.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Tap to enter ${widget.block.language} code...',
                              style: TextStyle(
                                fontFamily: 'Consolas',
                                fontSize: 13,
                                color: Colors.white.withAlpha(40),
                              ),
                            ),
                          )
                        : HighlightView(
                            _controller.text,
                            language: widget.block.language == 'cpp'
                                ? 'cpp'
                                : widget.block.language,
                            theme: monokaiSublimeTheme,
                            padding: const EdgeInsets.all(12),
                            textStyle: const TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                  ),
          ),
          // Output area
          if (_showOutput)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(60),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: const Border(
                  top: BorderSide(color: Color(0xFF2A2A4A)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, size: 12, color: Colors.white24),
                      const SizedBox(width: 4),
                      const Text('Output',
                          style: TextStyle(
                              color: Colors.white24,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() {
                          _showOutput = false;
                          widget.block.output = '';
                        }),
                        child:
                            const Icon(Icons.close, size: 12, color: Colors.white24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_isRunning)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF00D2FF),
                          ),
                        ),
                      ),
                    )
                  else
                    SelectableText(
                      widget.block.output,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: Color(0xFF51CF66),
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
