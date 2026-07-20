import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:notes_app/models/code_language.dart';
import 'package:notes_app/services/code_runner_service.dart';
import 'package:notes_app/widgets/content_blocks/base_block_widget.dart';

/// Keyword / snippet completions per language.
const Map<CodeLanguage, List<String>> _kCompletions = {
  CodeLanguage.python: [
    'print()',
    'len()',
    'range()',
    'enumerate()',
    'zip()',
    'map()',
    'filter()',
    'sorted()',
    'isinstance()',
    'type()',
    'int()',
    'str()',
    'list()',
    'dict()',
    'set()',
    'tuple()',
    'def ',
    'class ',
    'import ',
    'from ',
    'return ',
    'if ',
    'else:',
    'elif ',
    'for ',
    'while ',
    'try:',
    'except ',
    'finally:',
    'with ',
    'lambda ',
    'pass',
    'break',
    'continue',
    'None',
    'True',
    'False',
  ],
  CodeLanguage.javascript: [
    'console.log()',
    'console.error()',
    'function ',
    'const ',
    'let ',
    'var ',
    'return ',
    'if (',
    'else {',
    'else if (',
    'for (',
    'while (',
    'class ',
    'new ',
    'typeof ',
    'instanceof ',
    'null',
    'undefined',
    'true',
    'false',
    'async ',
    'await ',
    'Promise',
    'Array.from()',
    'Object.keys()',
    'Object.values()',
    'JSON.stringify()',
    'JSON.parse()',
  ],
  CodeLanguage.cpp: [
    '#include ',
    'int main()',
    'return 0;',
    'std::cout <<',
    'std::cin >>',
    'std::endl',
    'std::string',
    'std::vector',
    'std::map',
    'namespace ',
    'using namespace std;',
    'void ',
    'int ',
    'double ',
    'float ',
    'char ',
    'bool ',
    'if (',
    'else {',
    'for (',
    'while (',
    'class ',
    'struct ',
    'nullptr',
    'true',
    'false',
    'auto ',
    'const ',
    'static ',
  ],
};

List<String> _getSuggestions(String prefix, CodeLanguage language) {
  if (prefix.isEmpty) return [];
  final lower = prefix.toLowerCase();
  final completions = _kCompletions[language] ?? [];
  return completions
      .where((s) => s.toLowerCase().startsWith(lower))
      .take(6)
      .toList();
}

/// Jupyter-style code block with syntax highlighting and execution.
class CodeBlockWidget extends BaseBlockWidget {
  const CodeBlockWidget({
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
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends BaseBlockState<CodeBlockWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isRunning = false;
  bool _showOutput = false;
  bool _isEditing = false;
  List<String> _suggestions = [];
  Timer? _suggestionDebounce;

  /// Extracts the last incomplete word before the cursor for autocomplete matching.
  String _lastWordBeforeCursor() {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;
    final before = cursorPos >= 0 && cursorPos <= text.length
        ? text.substring(0, cursorPos)
        : text;
    return before.split(RegExp(r'[\s\n\(\)\{\}\[\]]')).last;
  }

  /// Returns the start index of the last incomplete word before the cursor.
  int _lastWordStart() {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;
    final before = cursorPos >= 0 && cursorPos <= text.length
        ? text.substring(0, cursorPos)
        : text;
    final match = RegExp(r'[^\s\n\(\)\{\}\[\]]*$').firstMatch(before);
    return match != null ? match.start : before.length;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content);
    _focusNode = FocusNode();
    _showOutput = widget.block.output.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant CodeBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final blockChanged = oldWidget.block.id != widget.block.id;
    if (blockChanged) {
      _controller
        ..text = widget.block.content
        ..selection =
            TextSelection.collapsed(offset: widget.block.content.length);
      _isEditing = false;
      _showOutput = widget.block.output.isNotEmpty;
      _suggestions = [];
      return;
    }

    if (!_isEditing && _controller.text != widget.block.content) {
      final selection = _controller.selection;
      final safeOffset = selection.isValid
          ? math.min(selection.baseOffset, widget.block.content.length)
          : widget.block.content.length;
      _controller.value = TextEditingValue(
        text: widget.block.content,
        selection: TextSelection.collapsed(offset: safeOffset),
      );
    }

    if (!_isRunning) {
      _showOutput = widget.block.output.isNotEmpty || _showOutput;
    }
  }

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Color get backgroundColor => const Color(0xFF1E1E2E);

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
      widget.block.output = result.stderr.isNotEmpty
          ? '${result.stdout}\n⚠ ${result.stderr}'
          : result.stdout;
    });
    widget.onChanged?.call();
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
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
                  color: widget.block.language == CodeLanguage.python
                      ? const Color(0xFF3776AB)
                      : const Color(0xFF00599C),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // Language dropdown
              DropdownButton<CodeLanguage>(
                value: widget.block.language,
                dropdownColor: const Color(0xFF252540),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                underline: const SizedBox(),
                isDense: true,
                items: CodeLanguage.values.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(lang.displayName),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => widget.block.language = v);
                    widget.onChanged?.call();
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
                    focusNode: _focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    autofocus: true,
                    onChanged: (v) {
                      widget.block.content = v;
                      widget.onChanged?.call();
                      // Debounce autocomplete suggestion updates
                      _suggestionDebounce?.cancel();
                      _suggestionDebounce = Timer(
                        const Duration(milliseconds: 80),
                        () {
                          if (mounted) {
                            setState(() {
                              _suggestions = _getSuggestions(
                                _lastWordBeforeCursor(),
                                widget.block.language,
                              );
                            });
                          }
                        },
                      );
                    },
                    style: const TextStyle(
                      fontFamily: 'Consolas',
                      fontSize: 13,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Enter ${widget.block.language.displayName} code...',
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
                            'Tap to enter ${widget.block.language.displayName} code...',
                            style: TextStyle(
                              fontFamily: 'Consolas',
                              fontSize: 13,
                              color: Colors.white.withAlpha(40),
                            ),
                          ),
                        )
                      : HighlightView(
                          _controller.text,
                          language: widget.block.language.name,
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
        // Autocomplete suggestions
        if (_isEditing && _suggestions.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E3A),
              border: Border.all(color: const Color(0xFF3A3A5A)),
              borderRadius: BorderRadius.circular(6),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _suggestions.map((suggestion) {
                return InkWell(
                  onTap: () {
                    final text = _controller.text;
                    final cursorPos = _controller.selection.baseOffset;
                    final after = cursorPos >= 0 && cursorPos <= text.length
                        ? text.substring(cursorPos)
                        : '';
                    final wordStart = _lastWordStart();
                    final before = wordStart <= text.length
                        ? text.substring(0, wordStart)
                        : text;
                    final newText = before + suggestion + after;
                    final newCursor = wordStart + suggestion.length;
                    _controller.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newCursor),
                    );
                    widget.block.content = newText;
                    widget.onChanged?.call();
                    setState(() => _suggestions = []);
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontSize: 12,
                        color: Color(0xFF00D2FF),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                    IconButton(
                      onPressed: () => setState(() {
                        _showOutput = false;
                        widget.block.output = '';
                      }),
                      icon: const Icon(Icons.close,
                          size: 12, color: Colors.white24),
                      tooltip: 'Clear output',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
    );
  }
}
