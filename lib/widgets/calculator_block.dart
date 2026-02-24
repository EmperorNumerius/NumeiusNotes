import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:notes_app/models/content_block.dart';

enum _Tab { calc, graph, table, vars }

class CalculatorBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback onChanged;
  const CalculatorBlockWidget({super.key, required this.block, required this.onChanged});
  @override
  State<CalculatorBlockWidget> createState() => _CalculatorBlockWidgetState();
}

class _CalculatorBlockWidgetState extends State<CalculatorBlockWidget> {
  final _expr = TextEditingController();
  _Tab _tab = _Tab.calc;
  String _result = '';
  bool _deg = true;
  double _ans = 0;
  final Map<String, double> _vars = {};
  final List<String> _history = [];
  final List<String> _y = List.filled(6, '');
  final Map<String, double> _win = {'xmin': -10, 'xmax': 10, 'ymin': -10, 'ymax': 10};
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

  double _eval(String e, {double? x}) => _Parser(e, _deg, _vars, _ans, x).parse();

  String _fmt(double v) {
    if (v.isNaN) return 'NaN';
    if (!v.isFinite) return v.isNegative ? '-Inf' : 'Inf';
    return v.toStringAsFixed(10).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _run() {
    final q = _expr.text.trim();
    if (q.isEmpty) return;
    try {
      final v = _eval(q);
      _ans = v;
      _result = _fmt(v);
      _history.insert(0, '$q = $_result');
      if (_history.length > 20) _history.removeRange(20, _history.length);
    } catch (_) {
      _result = 'Error';
    }
    _save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFAA5C).withAlpha(70)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            _chip('Calc', _tab == _Tab.calc, () => setState(() => _tab = _Tab.calc)),
            _chip('Graph', _tab == _Tab.graph, () => setState(() => _tab = _Tab.graph)),
            _chip('Table', _tab == _Tab.table, () => setState(() => _tab = _Tab.table)),
            _chip('Vars', _tab == _Tab.vars, () => setState(() => _tab = _Tab.vars)),
            const Spacer(),
            _chip(_deg ? 'DEG' : 'RAD', true, () {
              _deg = !_deg;
              _save();
              setState(() {});
            }),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFF1F1F3A)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: on ? const Color(0xFFFFAA5C).withAlpha(30) : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(t, style: TextStyle(color: on ? const Color(0xFFFFAA5C) : Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
    ),
  );

  Widget _calcView() {
    final keys = [
      ['7', '8', '9', '/', 'sin('],
      ['4', '5', '6', '*', 'cos('],
      ['1', '2', '3', '-', 'tan('],
      ['0', '.', '(', ')', '+'],
      ['Ans', '^', 'sqrt(', 'ln(', 'log('],
      ['A', 'B', 'C', 'X', '='],
    ];
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        TextField(
          controller: _expr,
          onChanged: (_) => _save(),
          style: const TextStyle(color: Colors.white, fontFamily: 'Courier New', fontSize: 13),
          decoration: InputDecoration(hintText: 'Expression', filled: true, fillColor: Colors.white.withAlpha(8), isDense: true),
        ),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('Result: ${_result.isEmpty ? '-' : _result}', style: TextStyle(color: _result == 'Error' ? const Color(0xFFFF6B6B) : const Color(0xFF00D2FF), fontWeight: FontWeight.w700))),
          IconButton(onPressed: () { _expr.clear(); _result = ''; _save(); setState(() {}); }, icon: const Icon(Icons.clear_rounded, size: 16)),
          IconButton(onPressed: _run, icon: const Icon(Icons.play_arrow_rounded, size: 18)),
        ]),
        ...keys.map((r) => Row(children: r.map((k) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: GestureDetector(
              onTap: () {
                if (k == '=') {
                  _run();
                } else {
                  _expr.text += k;
                  _expr.selection = TextSelection.collapsed(offset: _expr.text.length);
                  _save();
                  setState(() {});
                }
              },
              child: Container(height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: k == '=' ? const Color(0xFF00D2FF).withAlpha(30) : Colors.white.withAlpha(8), borderRadius: BorderRadius.circular(8)), child: Text(k, style: TextStyle(color: k == '=' ? const Color(0xFF00D2FF) : Colors.white, fontSize: 12))),
            ),
          ),
        )).toList())),
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(height: 70, child: ListView(children: _history.take(4).map((e) => Text(e, style: TextStyle(color: Colors.white.withAlpha(130), fontFamily: 'Courier New', fontSize: 11))).toList())),
        ],
      ]),
    );
  }

  Widget _graphView() => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(children: [
      ...List.generate(6, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: TextField(
          controller: TextEditingController(text: _y[i])..selection = TextSelection.collapsed(offset: _y[i].length),
          onChanged: (v) { _y[i] = v; _save(); },
          style: const TextStyle(color: Colors.white, fontFamily: 'Courier New', fontSize: 11),
          decoration: InputDecoration(isDense: true, filled: true, fillColor: Colors.white.withAlpha(8), prefixText: 'Y${i + 1}='),
        ),
      )),
      const SizedBox(height: 6),
      SizedBox(
        height: 220,
        child: CustomPaint(
          painter: _GraphPainter(
            y: _y,
            win: _win,
            eval: (e, x) => _eval(e, x: x),
          ),
          child: Container(),
        ),
      ),
    ]),
  );

  Widget _tableView() {
    final start = _tbl['start'] ?? -5;
    final step = _tbl['step'] ?? 1;
    final xs = List.generate(16, (i) => start + i * step);
    final active = _y.asMap().entries.where((e) => e.value.trim().isNotEmpty).take(3).toList();
    return Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: 300,
        child: SingleChildScrollView(
          child: Table(
            border: TableBorder.all(color: Colors.white.withAlpha(20)),
            children: [
              TableRow(children: [const _Cell('X', h: true), ...active.map((f) => _Cell('Y${f.key + 1}', h: true))]),
              ...xs.map((x) => TableRow(children: [
                _Cell(_fmt(x)),
                ...active.map((f) {
                  try { return _Cell(_fmt(_eval(f.value, x: x))); } catch (_) { return const _Cell('Err'); }
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
      height: 320,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 3.2, crossAxisSpacing: 6, mainAxisSpacing: 6),
        itemCount: names.length,
        itemBuilder: (context, i) {
          final k = names[i];
          final v = _vars[k];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(color: Colors.white.withAlpha(8), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Text('$k=', style: const TextStyle(color: Color(0xFFFFAA5C), fontWeight: FontWeight.w700, fontSize: 12)),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: v?.toString() ?? '')..selection = TextSelection.collapsed(offset: (v?.toString() ?? '').length),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  onChanged: (s) { final p = double.tryParse(s); if (p == null) { _vars.remove(k); } else { _vars[k] = p; } _save(); },
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Courier New'),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
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
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: Text(t, textAlign: TextAlign.center, style: TextStyle(color: h ? const Color(0xFF00D2FF) : Colors.white, fontSize: 11, fontFamily: 'Courier New', fontWeight: h ? FontWeight.w700 : FontWeight.w500)),
  );
}

class _GraphPainter extends CustomPainter {
  final List<String> y;
  final Map<String, double> win;
  final double Function(String expr, double x) eval;
  const _GraphPainter({required this.y, required this.win, required this.eval});
  @override
  void paint(Canvas c, Size s) {
    final xmin = win['xmin'] ?? -10, xmax = win['xmax'] ?? 10, ymin = win['ymin'] ?? -10, ymax = win['ymax'] ?? 10;
    if (xmax <= xmin || ymax <= ymin) return;
    Offset px(double x, double v) => Offset((x - xmin) / (xmax - xmin) * s.width, s.height - (v - ymin) / (ymax - ymin) * s.height);
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF101027));
    final g = Paint()..color = Colors.white.withAlpha(16)..strokeWidth = 1;
    for (var i = 0; i <= 10; i++) { final x = s.width * i / 10, y = s.height * i / 10; c.drawLine(Offset(x, 0), Offset(x, s.height), g); c.drawLine(Offset(0, y), Offset(s.width, y), g); }
    final colors = const [Color(0xFF00D2FF), Color(0xFFFF6B6B), Color(0xFF51CF66), Color(0xFFFFD43B), Color(0xFFB197FC), Color(0xFF38D9A9)];
    for (var i = 0; i < y.length; i++) {
      final e = y[i].trim();
      if (e.isEmpty) continue;
      final p = Paint()..color = colors[i]..style = PaintingStyle.stroke..strokeWidth = 1.8;
      final path = Path();
      var started = false;
      for (var ix = 0; ix <= s.width.toInt(); ix++) {
        final x = xmin + (ix / s.width) * (xmax - xmin);
        try {
          final v = eval(e, x);
          if (!v.isFinite || v.isNaN) { started = false; continue; }
          final pt = px(x, v);
          if (!started) { path.moveTo(pt.dx, pt.dy); started = true; } else { path.lineTo(pt.dx, pt.dy); }
        } catch (_) { started = false; }
      }
      c.drawPath(path, p);
    }
  }
  @override
  bool shouldRepaint(covariant _GraphPainter old) => old.y != y || old.win != win;
}

class _Parser {
  final String i; final bool deg; final Map<String, double> vars; final double ans; final double? x; int p = 0;
  _Parser(this.i, this.deg, this.vars, this.ans, this.x);
  double parse() { final v = _e(); _s(); if (p < i.length) throw const FormatException(); return v; }
  double _e() { var l = _t(); while (true) { _s(); if (_c('+')) l += _t(); else if (_c('-')) l -= _t(); else return l; } }
  double _t() { var l = _pow(); while (true) { _s(); if (_c('*')) l *= _pow(); else if (_c('/')) l /= _pow(); else return l; } }
  double _pow() { var b = _u(); _s(); if (_c('^')) b = math.pow(b, _u()).toDouble(); return b; }
  double _u() { _s(); if (_c('+')) return _u(); if (_c('-')) return -_u(); return _p(); }
  double _p() {
    _s();
    if (_c('(')) { final v = _e(); if (!_c(')')) throw const FormatException(); return v; }
    if (_a(_ch())) { final n = _id(); _s(); if (_c('(')) { final a = _e(); if (!_c(')')) throw const FormatException(); return _fn(n, a); } return _val(n); }
    return _num();
  }
  double _fn(String n, double a) { final k = n.toLowerCase(); final t = (deg && (k == 'sin' || k == 'cos' || k == 'tan')) ? a * math.pi / 180 : a; switch (k) { case 'sin': return math.sin(t); case 'cos': return math.cos(t); case 'tan': return math.tan(t); case 'log': return math.log(a) / math.ln10; case 'ln': return math.log(a); case 'sqrt': return math.sqrt(a); case 'abs': return a.abs(); default: throw const FormatException(); } }
  double _val(String n) { final k = n.toUpperCase(); if (k == 'ANS') return ans; if (k == 'PI') return math.pi; if (k == 'E') return math.e; if (k == 'X') return x ?? 0; if (k.length == 1 && vars.containsKey(k)) return vars[k]!; throw const FormatException(); }
  double _num() { final s = p; while (p < i.length && _d(i[p])) p++; if (p < i.length && i[p] == '.') { p++; while (p < i.length && _d(i[p])) p++; } if (s == p) throw const FormatException(); return double.parse(i.substring(s, p)); }
  String _id() { final s = p; while (p < i.length && (_a(i[p]) || _d(i[p]))) p++; return i.substring(s, p); }
  bool _c(String c) { _s(); if (p < i.length && i[p] == c) { p++; return true; } return false; }
  void _s() { while (p < i.length && i[p] == ' ') p++; }
  String _ch() => p < i.length ? i[p] : '';
  bool _d(String s) => s.codeUnitAt(0) >= 48 && s.codeUnitAt(0) <= 57;
  bool _a(String s) { if (s.isEmpty) return false; final c = s.codeUnitAt(0); return (c >= 65 && c <= 90) || (c >= 97 && c <= 122); }
}

