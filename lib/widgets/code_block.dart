import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:notes_app/models/code_language.dart';
import 'package:notes_app/services/code_runner_service.dart';
import 'package:notes_app/widgets/content_blocks/base_block_widget.dart';

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

  static final _tokenSplitRegex = RegExp(r'[\s\(\)\{\}\[\],;]');

  static const Map<CodeLanguage, List<String>> _languageSuggestions = {
    CodeLanguage.python: [
      'print()',
      'def',
      'class',
      'import',
      'for',
      'while',
      'if',
      'elif',
      'else',
      'return',
      'len()',
      'range()',
      'list',
      'dict',
      'try',
      'except',
    ],
    CodeLanguage.javascript: [
      'console.log()',
      'function',
      'const',
      'let',
      'var',
      'if',
      'else',
      'for',
      'while',
      'return',
      'async',
      'await',
      'Array',
      'Object',
      'map()',
      'filter()',
    ],
    CodeLanguage.cpp: [
      '#include <iostream>',
      'int main()',
      'std::cout <<',
      'std::cin >>',
      'if',
      'else',
      'for',
      'while',
      'return 0;',
      'std::vector',
      'std::string',
      'using namespace std;',
    ],
  };

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
                  child: RawAutocomplete<String>(
                    textEditingController: _controller,
                    focusNode: _focusNode,
                    optionsBuilder: (textEditingValue) {
                      final input = textEditingValue.text;
                      final cursorIndex = textEditingValue.selection.baseOffset;
                      if (input.isEmpty || cursorIndex < 0) {
                        return const Iterable<String>.empty();
                      }

                      final prefixText = input.substring(0, cursorIndex);
                      final token = prefixText.split(_tokenSplitRegex).last;
                      if (token.isEmpty) {
                        return const Iterable<String>.empty();
                      }

                      final suggestions =
                          _languageSuggestions[widget.block.language] ??
                              const [];
                      return suggestions.where(
                        (option) => option
                            .toLowerCase()
                            .startsWith(token.toLowerCase()),
                      );
                    },
                    onSelected: (selection) {
                      final currentText = _controller.text;
                      final selectionRange = _controller.selection;
                      if (!selectionRange.isValid) {
                        _controller.text = '$currentText$selection';
                        _controller.selection = TextSelection.collapsed(
                          offset: _controller.text.length,
                        );
                        widget.onChanged?.call();
                        return;
                      }

                      final cursorIndex = selectionRange.baseOffset;
                      final prefixText = currentText.substring(0, cursorIndex);
                      final suffixText = currentText.substring(cursorIndex);
                      final token = prefixText.split(_tokenSplitRegex).last;
                      final tokenStart = cursorIndex - token.length;
                      final newText =
                          '${currentText.substring(0, tokenStart)}$selection$suffixText';

                      _controller.value = TextEditingValue(
                        text: newText,
                        selection: TextSelection.collapsed(
                          offset: tokenStart + selection.length,
                        ),
                      );
                      widget.onChanged?.call();
                    },
                    fieldViewBuilder: (context, textEditingController,
                        focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        autofocus: true,
                        onChanged: (v) {
                          widget.block.content = v;
                          widget.onChanged?.call();
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
                          hintStyle:
                              TextStyle(color: Colors.white.withAlpha(40)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: const Color(0xFF252540),
                          elevation: 6,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: 180, maxWidth: 260),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontFamily: 'Consolas',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
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
                      child: const Icon(Icons.close,
                          size: 12, color: Colors.white24),
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
