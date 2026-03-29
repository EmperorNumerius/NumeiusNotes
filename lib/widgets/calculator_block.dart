import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes_app/models/content_block.dart';

enum _Tab { calc, graph, table, vars }

class CalculatorBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback onChanged;
  const CalculatorBlockWidget(
      {super.key, required this.block, required this.onChanged});
  @override
  State<CalculatorBlockWidget> createState() => _CalculatorBlockWidgetState();
}

class _CalculatorBlockWidgetState extends State<CalculatorBlockWidget> {
  // Threshold below which a double is treated as an integer for display.
  static const double _kRoundingTolerance = 1e-10;
  // Largest integer value that fits exactly in a double without loss.
  static const double _kIntegerDisplayLimit = 1e15;

  static final _trailingZerosRegex = RegExp(r'\.?0+$');
  final _expr = TextEditingController();
  _Tab _tab = _Tab.calc;
  String _result = '';
  bool _deg = true;
  double _ans = 0;
  final Map<String, double> _vars = {};
  final List<String> _history = [];
  final List<String> _y = List.filled(6, '');
  final Map<String, double> _win = {
    'xmin': -10,
    'xmax': 10,
    'ymin': -10,
    'ymax': 10
  };
  final Map<String, double> _tbl = {'start': -5, 'step': 1};

  @override
  void initState() {
    super.initState();
    final m = widget.block.metadata;
    _expr.text = (m['expression'] as String?) ?? '';
    _result = (m['result'] as String?) ?? '';
    _deg = (m['mode'] as String?) != 'rad';
    _ans = (m['ans'] as num?)?.toDouble() ?? 0;
    _history.addAll(List<String>.from(m['history'] as List? ?? const []));
    final vars = m['vars'] as Map?;
    if (vars != null) {
      for (final e in vars.entries) {
        final k = e.key.toString().toUpperCase();
        final v = (e.value as num?)?.toDouble();
        if (k.length == 1 && v != null) _vars[k] = v;
      }
    }
    final fy = m['functionsY'] as List?;
    if (fy != null) {
      for (var i = 0; i < math.min(6, fy.length); i++) {
        _y[i] = fy[i].toString();
      }
    }
    final w = m['window'] as Map?;
    if (w != null) {
      for (final k in _win.keys) {
        final v = (w[k] as num?)?.toDouble();
        if (v != null) _win[k] = v;
      }
    }
    final t = m['tableSettings'] as Map?;
    if (t != null) {
      for (final k in _tbl.keys) {
        final v = (t[k] as num?)?.toDouble();
        if (v != null) _tbl[k] = v;
      }
    }
  }

  @override
  void dispose() {
    _expr.dispose();
    super.dispose();
  }

  void _save() {
    final m = widget.block.metadata;
    m['expression'] = _expr.text;
    m['result'] = _result;
    m['mode'] = _deg ? 'deg' : 'rad';
    m['ans'] = _ans;
    m['vars'] = _vars;
    m['history'] = _history;
    m['functionsY'] = _y;
    m['window'] = _win;
    m['tableSettings'] = _tbl;
    widget.block.content = _expr.text;
    widget.onChanged();
  }

  double _eval(String e, {double? x}) =>
      _Parser(e, _deg, _vars, _ans, x).parse();

  String _fmt(double v) {
    if (v.isNaN) return 'NaN';
    if (!v.isFinite) return v.isNegative ? '-Inf' : 'Inf';
    final rounded = v.roundToDouble();
    if ((v - rounded).abs() < _kRoundingTolerance && rounded.abs() < _kIntegerDisplayLimit) {
      return rounded.toInt().toString();
    }
    return v.toStringAsFixed(10).replaceFirst(_trailingZerosRegex, '');
  }

  void _input(String k) {
    final ctrl = _expr;
    final sel = ctrl.selection;
    final text = ctrl.text;
    final pos = sel.isValid ? sel.baseOffset : text.length;
    final newText = text.substring(0, pos) + k + text.substring(pos);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + k.length),
    );
    _save();
    setState(() {});
  }

  void _backspace() {
    final ctrl = _expr;
    final text = ctrl.text;
    if (text.isEmpty) return;
    final pos = ctrl.selection.isValid
        ? ctrl.selection.baseOffset.clamp(0, text.length)
        : text.length;
    if (pos == 0) return;
    final newText = text.substring(0, pos - 1) + text.substring(pos);
    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: pos - 1),
    );
    _save();
    setState(() {});
  }

  void _run() {
    final q = _expr.text.trim();
    if (q.isEmpty) return;
    try {
      final v = _eval(q);
      _ans = v;
      _result = _fmt(v);
      _history.insert(0, '$q = $_result');
      if (_history.length > 30) _history.removeRange(30, _history.length);
    } catch (_) {
      _result = 'Error';
    }
    _save();
    setState(() {});
  }

  static const _kAccent = Color(0xFFFFAA5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAccent.withAlpha(60)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          child: Row(children: [
            _chip('Calc', _tab == _Tab.calc,
                () => setState(() => _tab = _Tab.calc)),
            _chip('Graph', _tab == _Tab.graph,
                () => setState(() => _tab = _Tab.graph)),
            _chip('Table', _tab == _Tab.table,
                () => setState(() => _tab = _Tab.table)),
            _chip('Vars', _tab == _Tab.vars,
                () => setState(() => _tab = _Tab.vars)),
            const Spacer(),
            _chip(_deg ? 'DEG' : 'RAD', true, () {
              _deg = !_deg;
              _save();
              setState(() {});
            }),
          ]),
        ),
        Divider(height: 1, color: Colors.white.withAlpha(12)),
        if (_tab == _Tab.calc) _calcView(),
        if (_tab == _Tab.graph) _graphView(),
        if (_tab == _Tab.table) _tableView(),
        if (_tab == _Tab.vars) _varsView(),
      ]),
    );
  }

  Widget _chip(String t, bool on, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: on ? _kAccent.withAlpha(30) : Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: on ? _kAccent.withAlpha(60) : Colors.transparent),
          ),
          child: Text(t,
              style: TextStyle(
                  color: on ? _kAccent : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ),
      );

  Widget _calcView() {
    final keys = [
      ['sin(', 'cos(', 'tan(', 'asin(', 'acos('],
      ['atan(', 'sqrt(', 'ln(', 'log(', 'abs('],
      ['floor(', 'ceil(', 'round(', 'exp(', '^'],
      ['7', '8', '9', '(', ')'],
      ['4', '5', '6', '*', '/'],
      ['1', '2', '3', '+', '-'],
      ['0', '.', '%', 'Ans', 'pi'],
      ['X', 'A', 'BACK', 'CLR', '='],
    ];

    final isError = _result == 'Error';
    final resultColor = isError ? const Color(0xFFFF6B6B) : const Color(0xFF00D2FF);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withAlpha(14)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: TextField(
            controller: _expr,
            onChanged: (_) => _save(),
            onSubmitted: (_) => _run(),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Courier New',
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Expression\u2026',
              hintStyle: TextStyle(color: Colors.white.withAlpha(50), fontSize: 13),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: resultColor.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: resultColor.withAlpha(30)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _result.isEmpty ? '\u2014' : '= $_result',
                  style: TextStyle(
                    color: resultColor,
                    fontFamily: 'Courier New',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_result.isNotEmpty && !isError)
                Tooltip(
                  message: 'Copy result',
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _result));
                    },
                    child: Icon(
                      Icons.copy_rounded,
                      size: 15,
                      color: resultColor.withAlpha(130),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...keys.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: row.map((k) {
              final isEquals = k == '=';
              final isClear = k == 'CLR';
              final isBack = k == 'BACK';
              final isFunc = !_isDigitOrOp(k) && !isEquals && !isClear && !isBack;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _calcKey(k, isEquals: isEquals, isClear: isClear, isBack: isBack, isFunc: isFunc),
                ),
              );
            }).toList(),
          ),
        )),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 10),
          Divider(color: Colors.white.withAlpha(12), height: 1),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              itemCount: _history.length > 6 ? 6 : _history.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _history[i],
                  style: TextStyle(
                    color: Colors.white.withAlpha(110),
                    fontFamily: 'Courier New',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  bool _isDigitOrOp(String k) {
    const ops = {
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
      '.', '+', '-', '*', '/', '(', ')', '^', '%', 'pi',
      'Ans', 'X', 'A', 'B', 'C',
    };
    return ops.contains(k);
  }

  Widget _calcKey(
    String k, {
    bool isEquals = false,
    bool isClear = false,
    bool isBack = false,
    bool isFunc = false,
  }) {
    Color bg;
    Color fg;
    IconData? icon;
    String label = k;

    if (isEquals) {
      bg = const Color(0xFF00D2FF).withAlpha(35);
      fg = const Color(0xFF00D2FF);
    } else if (isClear) {
      bg = const Color(0xFFFF6B6B).withAlpha(22);
      fg = const Color(0xFFFF6B6B);
    } else if (isBack) {
      bg = Colors.white.withAlpha(10);
      fg = Colors.white70;
      icon = Icons.backspace_outlined;
      label = '';
    } else if (isFunc) {
      bg = _kAccent.withAlpha(15);
      fg = _kAccent;
    } else {
      bg = Colors.white.withAlpha(8);
      fg = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        if (isEquals) {
          _run();
        } else if (isClear) {
          _expr.clear();
          _result = '';
          _save();
          setState(() {});
        } else if (isBack) {
          _backspace();
        } else if (k == 'pi') {
          _input('pi');
        } else if (k == 'Ans') {
          _input('Ans');
        } else {
          _input(k);
        }
      },
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isEquals
                  ? const Color(0xFF00D2FF).withAlpha(50)
                  : Colors.white.withAlpha(8)),
        ),
        child: icon != null
            ? Icon(icon, size: 15, color: fg)
            : Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: k.length > 4 ? 10 : 13,
                  fontWeight: isFunc ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Courier New',
                ),
              ),
      ),
    );
  }

  Widget _graphView() => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          ...List.generate(
              6,
              (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextField(
                      controller: TextEditingController(text: _y[i])
                        ..selection =
                            TextSelection.collapsed(offset: _y[i].length),
                      onChanged: (v) {
                        _y[i] = v;
                        _save();
                      },
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Courier New',
                          fontSize: 12),
                      decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white.withAlpha(8),
                          prefixText: 'Y${i + 1}=',
                          prefixStyle: TextStyle(
                              color: _graphColors[i],
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ),
                  )),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 240,
              child: CustomPaint(
                painter: _GraphPainter(
                  y: _y,
                  win: _win,
                  eval: (e, x) => _eval(e, x: x),
                ),
                child: Container(),
              ),
            ),
          ),
        ]),
      );

  static const _graphColors = [
    Color(0xFF00D2FF), Color(0xFFFF6B6B), Color(0xFF51CF66),
    Color(0xFFFFD43B), Color(0xFFB197FC), Color(0xFF38D9A9),
  ];

  Widget _tableView() {
    final start = _tbl['start'] ?? -5;
    final step = _tbl['step'] ?? 1;
    final xs = List.generate(16, (i) => start + i * step);
    final active = _y.asMap().entries.where((e) => e.value.trim().isNotEmpty).take(3).toList();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 320,
        child: SingleChildScrollView(
          child: Table(
            border: TableBorder.all(color: Colors.white.withAlpha(18)),
            children: [
              TableRow(children: [
                const _Cell('X', h: true),
                ...active.map((f) => _Cell('Y${f.key + 1}', h: true))
              ]),
              ...xs.map((x) => TableRow(children: [
                    _Cell(_fmt(x)),
                    ...active.map((f) {
                      try {
                        return _Cell(_fmt(_eval(f.value, x: x)));
                      } catch (_) {
                        return const _Cell('Err');
                      }
                    }),
                  ])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _varsView() {
    final names = List.generate(26, (i) => String.fromCharCode(65 + i));
    return SizedBox(
      height: 340,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 3.0,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6),
        itemCount: names.length,
        itemBuilder: (context, i) {
          final k = names[i];
          final v = _vars[k];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                color: Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withAlpha(10))),
            child: Row(children: [
              Text('$k=',
                  style: const TextStyle(
                      color: _kAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              Expanded(
                child: TextField(
                  controller:
                      TextEditingController(text: v?.toString() ?? '')
                        ..selection = TextSelection.collapsed(
                            offset: (v?.toString() ?? '').length),
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  onChanged: (s) {
                    final p = double.tryParse(s);
                    if (p == null) {
                      _vars.remove(k);
                    } else {
                      _vars[k] = p;
                    }
                    _save();
                  },
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontFamily: 'Courier New'),
                  decoration:
                      const InputDecoration(border: InputBorder.none, isDense: true),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String t;
  final bool h;
  const _Cell(this.t, {this.h = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: h ? const Color(0xFF00D2FF) : Colors.white,
                fontSize: 11,
                fontFamily: 'Courier New',
                fontWeight: h ? FontWeight.w700 : FontWeight.w400)),
      );
}

class _GraphPainter extends CustomPainter {
  final List<String> y;
  final Map<String, double> win;
  final double Function(String expr, double x) eval;
  const _GraphPainter({required this.y, required this.win, required this.eval});
  @override
  void paint(Canvas c, Size s) {
    final xmin = win['xmin'] ?? -10,
        xmax = win['xmax'] ?? 10,
        ymin = win['ymin'] ?? -10,
        ymax = win['ymax'] ?? 10;
    if (xmax <= xmin || ymax <= ymin) return;
    Offset px(double x, double v) => Offset(
        (x - xmin) / (xmax - xmin) * s.width,
        s.height - (v - ymin) / (ymax - ymin) * s.height);
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF090916));
    final g = Paint()
      ..color = Colors.white.withAlpha(12)
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 10; i++) {
      final gx = s.width * i / 10, gy = s.height * i / 10;
      c.drawLine(Offset(gx, 0), Offset(gx, s.height), g);
      c.drawLine(Offset(0, gy), Offset(s.width, gy), g);
    }
    final ax = Paint()
      ..color = Colors.white.withAlpha(40)
      ..strokeWidth = 1;
    if (0 >= ymin && 0 <= ymax) {
      c.drawLine(
          Offset(0, s.height * (1 - (-ymin) / (ymax - ymin))),
          Offset(s.width, s.height * (1 - (-ymin) / (ymax - ymin))),
          ax);
    }
    if (0 >= xmin && 0 <= xmax) {
      c.drawLine(
          Offset(s.width * (-xmin) / (xmax - xmin), 0),
          Offset(s.width * (-xmin) / (xmax - xmin), s.height),
          ax);
    }
    const colors = [
      Color(0xFF00D2FF), Color(0xFFFF6B6B), Color(0xFF51CF66),
      Color(0xFFFFD43B), Color(0xFFB197FC), Color(0xFF38D9A9),
    ];
    for (var i = 0; i < y.length; i++) {
      final e = y[i].trim();
      if (e.isEmpty) continue;
      final p = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..isAntiAlias = true;
      final path = Path();
      var started = false;
      for (var ix = 0; ix <= s.width.toInt(); ix++) {
        final x = xmin + (ix / s.width) * (xmax - xmin);
        try {
          final v = eval(e, x);
          if (!v.isFinite || v.isNaN) { started = false; continue; }
          final pt = px(x, v);
          if (!started) { path.moveTo(pt.dx, pt.dy); started = true; }
          else { path.lineTo(pt.dx, pt.dy); }
        } catch (_) { started = false; }
      }
      c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => old.y != y || old.win != win;
}

double _factorial(double n) {
  if (n < 0 || n != n.truncateToDouble()) throw const FormatException();
  // 171! overflows to infinity; cap at 170.
  if (n > 170) return double.infinity;
  var r = 1.0;
    for (var i = 2; i <= n.toInt(); i++) {
      r *= i;
    }
  return r;
}

class _Parser {
  final String i;
  final bool deg;
  final Map<String, double> vars;
  final double ans;
  final double? x;
  int p = 0;

  _Parser(this.i, this.deg, this.vars, this.ans, this.x);

  double parse() {
    final v = _expr();
    _skip();
    if (p < i.length) throw const FormatException();
    return v;
  }

  double _expr() {
    var l = _term();
    while (true) {
      _skip();
      if (_consume('+')) { l += _term(); }
      else if (_consume('-')) { l -= _term(); }
      else { return l; }
    }
  }

  double _term() {
    var l = _mod();
    while (true) {
      _skip();
      if (_consume('*')) { l *= _mod(); }
      else if (_consume('/')) { l /= _mod(); }
      else { return l; }
    }
  }

  double _mod() {
    var l = _pow();
    while (true) {
      _skip();
      if (_consume('%')) { l = l % _pow(); }
      else { return l; }
    }
  }

  double _pow() {
    var b = _fact();
    _skip();
    if (_consume('^')) b = math.pow(b, _pow()).toDouble();
    return b;
  }

  double _fact() {
    var b = _unary();
    _skip();
    if (p < i.length && i[p] == '!') { p++; b = _factorial(b); }
    return b;
  }

  double _unary() {
    _skip();
    if (_consume('+')) return _unary();
    if (_consume('-')) return -_unary();
    return _primary();
  }

  double _primary() {
    _skip();
    if (_consume('(')) {
      final v = _expr();
      if (!_consume(')')) throw const FormatException();
      return v;
    }
    if (_isAlpha(_peek())) {
      final n = _ident();
      _skip();
      if (_consume('(')) {
        final a = _expr();
        double? b;
        if (p < i.length && i[p] == ',') { p++; b = _expr(); }
        if (!_consume(')')) throw const FormatException();
        return _callFn(n, a, b);
      }
      return _lookupVar(n);
    }
    return _number();
  }

  double _callFn(String n, double a, double? b) {
    final k = n.toLowerCase();
    final toRad = deg && (k == 'sin' || k == 'cos' || k == 'tan');
    final rad = toRad ? a * math.pi / 180 : a;
    final fromRad = deg ? 180 / math.pi : 1.0;
    switch (k) {
      case 'sin': return math.sin(rad);
      case 'cos': return math.cos(rad);
      case 'tan': return math.tan(rad);
      case 'asin': return math.asin(a) * fromRad;
      case 'acos': return math.acos(a) * fromRad;
      case 'atan': return math.atan(a) * fromRad;
      case 'atan2':
        if (b == null) throw const FormatException();
        return math.atan2(a, b) * fromRad;
      case 'log': return math.log(a) / math.ln10;
      case 'log2': return math.log(a) / math.ln2;
      case 'ln': return math.log(a);
      case 'sqrt': return math.sqrt(a);
      case 'cbrt': return math.pow(a.abs(), 1.0 / 3.0).toDouble() * (a < 0 ? -1 : 1);
      case 'abs': return a.abs();
      case 'floor': return a.floorToDouble();
      case 'ceil': return a.ceilToDouble();
      case 'round': return a.roundToDouble();
      case 'exp': return math.exp(a);
      case 'sign': return a.sign;
      case 'max': if (b == null) throw const FormatException(); return math.max(a, b);
      case 'min': if (b == null) throw const FormatException(); return math.min(a, b);
      case 'pow': if (b == null) throw const FormatException(); return math.pow(a, b).toDouble();
      case 'ncr': if (b == null) throw const FormatException(); return _factorial(a) / (_factorial(b) * _factorial(a - b));
      case 'npr': if (b == null) throw const FormatException(); return _factorial(a) / _factorial(a - b);
      default: throw const FormatException();
    }
  }

  double _lookupVar(String n) {
    final k = n.toUpperCase();
    if (k == 'ANS') return ans;
    if (k == 'PI') return math.pi;
    if (k == 'E') return math.e;
    if (k == 'INF') return double.infinity;
    if (k == 'X') return x ?? 0;
    if (k.length == 1 && vars.containsKey(k)) return vars[k]!;
    throw const FormatException();
  }

  double _number() {
    final s = p;
    while (p < i.length && _isDigit(i[p])) {
      p++;
    }
    if (p < i.length && i[p] == '.') {
      p++;
      while (p < i.length && _isDigit(i[p])) {
        p++;
      }
    }
    if (s == p) throw const FormatException();
    return double.parse(i.substring(s, p));
  }

  String _ident() {
    final s = p;
    while (p < i.length && (_isAlpha(i[p]) || _isDigit(i[p]) || i[p] == '_')) {
      p++;
    }
    return i.substring(s, p);
  }

  bool _consume(String c) {
    _skip();
    if (p < i.length && i[p] == c) { p++; return true; }
    return false;
  }

  void _skip() {
    while (p < i.length && i[p] == ' ') {
      p++;
    }
  }

  String _peek() => p < i.length ? i[p] : '';
  bool _isDigit(String s) => s.codeUnitAt(0) >= 48 && s.codeUnitAt(0) <= 57;
  bool _isAlpha(String s) {
    if (s.isEmpty) return false;
    final c = s.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
  }
}
