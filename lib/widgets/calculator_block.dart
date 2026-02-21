import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes_app/models/content_block.dart';

/// Scientific calculator block — embedded inside a note.
class CalculatorBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback onChanged;

  const CalculatorBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<CalculatorBlockWidget> createState() => _CalculatorBlockWidgetState();
}

class _CalculatorBlockWidgetState extends State<CalculatorBlockWidget> {
  String _expression = '';
  String _result = '';
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadFromMetadata();
  }

  void _loadFromMetadata() {
    final meta = widget.block.metadata;
    _expression = meta['expression'] as String? ?? '';
    _result = meta['result'] as String? ?? '';
    _history = List<String>.from(meta['history'] as List? ?? []);
  }

  void _save() {
    widget.block.metadata['expression'] = _expression;
    widget.block.metadata['result'] = _result;
    widget.block.metadata['history'] = _history;
    widget.block.content = _result.isNotEmpty ? '$_expression = $_result' : _expression;
    widget.onChanged();
  }

  void _press(String key) {
    setState(() {
      switch (key) {
        case 'C':
          _expression = '';
          _result = '';
          break;
        case '⌫':
          if (_expression.isNotEmpty) {
            // Remove last token (function names or single char)
            for (final fn in ['sin(', 'cos(', 'tan(', 'log(', 'ln(', '√(']) {
              if (_expression.endsWith(fn)) {
                _expression = _expression.substring(0, _expression.length - fn.length);
                return;
              }
            }
            _expression = _expression.substring(0, _expression.length - 1);
          }
          break;
        case '=':
          _evaluate();
          break;
        case 'sin':
          _expression += 'sin(';
          break;
        case 'cos':
          _expression += 'cos(';
          break;
        case 'tan':
          _expression += 'tan(';
          break;
        case 'log':
          _expression += 'log(';
          break;
        case 'ln':
          _expression += 'ln(';
          break;
        case '√':
          _expression += '√(';
          break;
        case 'π':
          _expression += 'π';
          break;
        case 'e':
          _expression += 'e';
          break;
        case '^':
          _expression += '^';
          break;
        default:
          _expression += key;
      }
    });
    _save();
  }

  void _evaluate() {
    try {
      final result = _evalExpression(_expression);
      final display = result == result.roundToDouble() && result.abs() < 1e15
          ? result.toInt().toString()
          : result.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      setState(() {
        _result = display;
        if (_expression.isNotEmpty) {
          _history.insert(0, '$_expression = $display');
          if (_history.length > 5) _history = _history.sublist(0, 5);
        }
      });
    } catch (_) {
      setState(() => _result = 'Error');
    }
    _save();
  }

  /// Recursive descent parser for math expressions.
  double _evalExpression(String expr) {
    expr = expr.replaceAll(' ', '');
    // Replace constants
    expr = expr.replaceAll('π', '${math.pi}');
    expr = expr.replaceAll('e', '${math.e}');
    // But be careful not to replace 'e' inside numbers like 2.718...
    // Actually let's be smarter:
    // Re-do constant replacement carefully
    expr = _expression.replaceAll(' ', '');
    final replaced = StringBuffer();
    for (int i = 0; i < expr.length; i++) {
      if (expr[i] == 'π') {
        replaced.write(math.pi.toString());
      } else if (expr[i] == 'e' && !_isPartOfFunction(expr, i)) {
        replaced.write(math.e.toString());
      } else {
        replaced.write(expr[i]);
      }
    }
    final parser = _Parser(replaced.toString());
    final result = parser.parseExpression();
    return result;
  }

  bool _isPartOfFunction(String expr, int i) {
    // Check if 'e' is part of a function name
    if (i > 0 && expr[i - 1].contains(RegExp(r'[a-z]'))) return true;
    if (i < expr.length - 1 && expr[i + 1].contains(RegExp(r'[a-z]'))) return true;
    return false;
  }

  void _copyResult() {
    if (_result.isNotEmpty && _result != 'Error') {
      Clipboard.setData(ClipboardData(text: _result));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied $_result',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: const Color(0xFF1A1A2E),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7C3AED).withAlpha(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDisplay(),
          const Divider(height: 1, color: Color(0xFF1F1F3A)),
          _buildHistory(),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildDisplay() {
    return GestureDetector(
      onTap: _copyResult,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _expression.isEmpty ? '0' : _expression,
              style: TextStyle(
                color: Colors.white.withAlpha(_expression.isEmpty ? 40 : 180),
                fontSize: 18,
                fontFamily: 'Courier New',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '= $_result',
                style: TextStyle(
                  color: _result == 'Error'
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF00D2FF),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier New',
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _history.take(3).map((h) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(h,
                style: TextStyle(
                    color: Colors.white.withAlpha(30),
                    fontSize: 10,
                    fontFamily: 'Courier New'),
                textAlign: TextAlign.right),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButtons() {
    // Scientific row
    final sciRow = ['sin', 'cos', 'tan', 'log', 'ln', '√', 'π', 'e', '^'];
    // Main grid
    final mainRows = [
      ['C', '(', ')', '⌫'],
      ['7', '8', '9', '÷'],
      ['4', '5', '6', '×'],
      ['1', '2', '3', '−'],
      ['0', '.', '=', '+'],
    ];

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          // Scientific row
          Row(
            children: sciRow.map((k) {
              return Expanded(child: _calcButton(k, isSci: true));
            }).toList(),
          ),
          const SizedBox(height: 4),
          // Main grid
          ...mainRows.map((row) {
            return Row(
              children: row.map((k) {
                return Expanded(child: _calcButton(k));
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Widget _calcButton(String label, {bool isSci = false}) {
    final isOperator = '÷×−+^'.contains(label);
    final isEquals = label == '=';
    final isClear = label == 'C' || label == '⌫';

    Color bg;
    Color fg;
    if (isEquals) {
      bg = const Color(0xFF00D2FF).withAlpha(30);
      fg = const Color(0xFF00D2FF);
    } else if (isOperator) {
      bg = const Color(0xFF7C3AED).withAlpha(20);
      fg = const Color(0xFF7C3AED);
    } else if (isClear) {
      bg = const Color(0xFFFF6B6B).withAlpha(15);
      fg = const Color(0xFFFF6B6B);
    } else if (isSci) {
      bg = const Color(0xFF38D9A9).withAlpha(10);
      fg = const Color(0xFF38D9A9);
    } else {
      bg = Colors.white.withAlpha(6);
      fg = Colors.white.withAlpha(200);
    }

    return GestureDetector(
      onTap: () {
        // Map display chars to expression chars
        final mapped = switch (label) {
          '÷' => '/',
          '×' => '*',
          '−' => '-',
          _ => label,
        };
        _press(mapped);
      },
      child: Container(
        height: isSci ? 30 : 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withAlpha(15)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: isSci ? 11 : 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Simple recursive‑descent math parser
// ═══════════════════════════════════════════════════════════

class _Parser {
  final String input;
  int _pos = 0;

  _Parser(this.input);

  double parseExpression() {
    final result = _addSub();
    return result;
  }

  double _addSub() {
    var left = _mulDiv();
    while (_pos < input.length) {
      if (_char() == '+') {
        _pos++;
        left += _mulDiv();
      } else if (_char() == '-') {
        _pos++;
        left -= _mulDiv();
      } else {
        break;
      }
    }
    return left;
  }

  double _mulDiv() {
    var left = _power();
    while (_pos < input.length) {
      if (_char() == '*') {
        _pos++;
        left *= _power();
      } else if (_char() == '/') {
        _pos++;
        left /= _power();
      } else {
        break;
      }
    }
    return left;
  }

  double _power() {
    var base = _unary();
    if (_pos < input.length && _char() == '^') {
      _pos++;
      final exp = _unary();
      base = math.pow(base, exp).toDouble();
    }
    return base;
  }

  double _unary() {
    if (_pos < input.length && _char() == '-') {
      _pos++;
      return -_primary();
    }
    return _primary();
  }

  double _primary() {
    _skipSpaces();

    // Functions
    for (final fn in ['sin', 'cos', 'tan', 'log', 'ln']) {
      if (input.substring(_pos).startsWith('$fn(')) {
        _pos += fn.length;
        // fn might not have parens — but we added them
        final arg = _primary(); // will eat the parens via _primary -> group
        return switch (fn) {
          'sin' => math.sin(arg),
          'cos' => math.cos(arg),
          'tan' => math.tan(arg),
          'log' => math.log(arg) / math.ln10,
          'ln' => math.log(arg),
          _ => arg,
        };
      }
    }

    // Square root
    if (input.substring(_pos).startsWith('√(')) {
      _pos += 1; // skip √
      final arg = _primary();
      return math.sqrt(arg);
    }

    // Parenthesized group
    if (_pos < input.length && _char() == '(') {
      _pos++;
      final val = _addSub();
      if (_pos < input.length && _char() == ')') _pos++;
      return val;
    }

    // Number
    final start = _pos;
    while (_pos < input.length &&
        (_char().contains(RegExp(r'[0-9.]')))) {
      _pos++;
    }
    if (_pos > start) {
      return double.parse(input.substring(start, _pos));
    }

    throw FormatException('Unexpected character at position $_pos');
  }

  String _char() => input[_pos];

  void _skipSpaces() {
    while (_pos < input.length && input[_pos] == ' ') {
      _pos++;
    }
  }
}
