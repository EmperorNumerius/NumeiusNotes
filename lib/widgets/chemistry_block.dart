import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/periodic_table_data.dart';

enum _ChemTool {
  select,
  atom,
  bondSingle,
  bondDouble,
  bondTriple,
  text,
  erase,
  markup,
}

class _AtomNode {
  final String id;
  String symbol;
  Offset position;

  _AtomNode({
    required this.id,
    required this.symbol,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'x': position.dx,
        'y': position.dy,
      };

  factory _AtomNode.fromJson(Map<String, dynamic> json) {
    return _AtomNode(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
    );
  }
}

class _BondEdge {
  final String a;
  final String b;
  int order;

  _BondEdge({
    required this.a,
    required this.b,
    this.order = 1,
  });

  Map<String, dynamic> toJson() => {
        'a': a,
        'b': b,
        'order': order,
      };

  factory _BondEdge.fromJson(Map<String, dynamic> json) {
    return _BondEdge(
      a: json['a'] as String,
      b: json['b'] as String,
      order: (json['order'] as num?)?.toInt() ?? 1,
    );
  }
}

class _ChemLabel {
  String text;
  Offset position;

  _ChemLabel({
    required this.text,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'x': position.dx,
        'y': position.dy,
      };

  factory _ChemLabel.fromJson(Map<String, dynamic> json) {
    return _ChemLabel(
      text: json['text'] as String,
      position: Offset(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      ),
    );
  }
}

class _MarkupStroke {
  List<Offset> points;

  _MarkupStroke(this.points);

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      };

  factory _MarkupStroke.fromJson(Map<String, dynamic> json) {
    final raw = (json['points'] as List? ?? []);
    return _MarkupStroke(
      raw
          .map(
            (e) => Offset(
              (e['x'] as num).toDouble(),
              (e['y'] as num).toDouble(),
            ),
          )
          .toList(),
    );
  }
}

/// 2D chemistry structure editor with atom/bond editing + writable markup.
class ChemistryBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback onChanged;

  const ChemistryBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<ChemistryBlockWidget> createState() => _ChemistryBlockWidgetState();
}

class _ChemistryBlockWidgetState extends State<ChemistryBlockWidget> {
  static const Size _canvasSize = Size(620, 320);
  static const _defaultElements = ['C', 'H', 'O', 'N', 'S', 'P', 'Cl', 'Na'];

  final List<_AtomNode> _atoms = [];
  final List<_BondEdge> _bonds = [];
  final List<_ChemLabel> _labels = [];
  final List<_MarkupStroke> _markupStrokes = [];

  _ChemTool _tool = _ChemTool.atom;
  String _selectedElement = 'C';
  String? _selectedBondAtomId;
  String? _dragAtomId;
  _MarkupStroke? _activeMarkup;

  @override
  void initState() {
    super.initState();
    _loadFromMetadata();
  }

  void _loadFromMetadata() {
    final meta = widget.block.metadata;

    final atomsRaw = meta['atoms'] as List?;
    if (atomsRaw != null) {
      _atoms.addAll(
        atomsRaw
            .map((e) => _AtomNode.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }

    final bondsRaw = meta['bonds'] as List?;
    if (bondsRaw != null) {
      _bonds.addAll(
        bondsRaw
            .map((e) => _BondEdge.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }

    final labelsRaw = meta['labels'] as List?;
    if (labelsRaw != null) {
      _labels.addAll(
        labelsRaw
            .map((e) => _ChemLabel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
    }

    final markupRaw = meta['markupStrokes'] as List?;
    if (markupRaw != null) {
      _markupStrokes.addAll(
        markupRaw
            .map(
              (e) => _MarkupStroke.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList(),
      );
    }

    // Legacy migration from formula builder metadata.
    if (_atoms.isEmpty && meta.containsKey('compound')) {
      final legacy = meta['compound'] as List<dynamic>? ?? [];
      var x = 70.0;
      const y = 150.0;
      for (var i = 0; i < legacy.length; i++) {
        final item = Map<String, dynamic>.from(legacy[i] as Map);
        final atomic = item['atomicNumber'] as int?;
        final subscript = item['subscript'] as int? ?? 1;
        final symbol = allElements
            .firstWhere(
              (el) => el.atomicNumber == atomic,
              orElse: () => const ChemElement(
                atomicNumber: 6,
                symbol: 'C',
                name: 'Carbon',
                mass: 12.011,
                category: ElementCategory.nonmetal,
                row: 2,
                col: 14,
              ),
            )
            .symbol;

        for (var n = 0; n < subscript; n++) {
          final id = 'a_${_atoms.length}_${DateTime.now().microsecondsSinceEpoch}';
          _atoms.add(_AtomNode(id: id, symbol: symbol, position: Offset(x, y)));
          if (_atoms.length > 1) {
            _bonds.add(
              _BondEdge(a: _atoms[_atoms.length - 2].id, b: id, order: 1),
            );
          }
          x += 50;
        }
      }
      _save();
    }
  }

  void _save() {
    final meta = widget.block.metadata;
    meta['atoms'] = _atoms.map((a) => a.toJson()).toList();
    meta['bonds'] = _bonds.map((b) => b.toJson()).toList();
    meta['labels'] = _labels.map((l) => l.toJson()).toList();
    meta['markupStrokes'] = _markupStrokes.map((s) => s.toJson()).toList();
    meta['viewState'] = {
      'tool': _tool.name,
      'selectedElement': _selectedElement,
    };
    meta['formula'] = _formulaString();
    meta['molarMass'] = _molarMass();

    widget.block.content = _formulaString();
    widget.onChanged();
  }

  String _formulaString() {
    if (_atoms.isEmpty) return '';
    final counts = <String, int>{};
    for (final atom in _atoms) {
      counts.update(atom.symbol, (v) => v + 1, ifAbsent: () => 1);
    }

    final ordered = <String>[];
    if (counts.containsKey('C')) ordered.add('C');
    if (counts.containsKey('H')) ordered.add('H');
    final rest = counts.keys.where((k) => k != 'C' && k != 'H').toList()..sort();
    ordered.addAll(rest);

    final buf = StringBuffer();
    for (final symbol in ordered) {
      buf.write(symbol);
      final n = counts[symbol]!;
      if (n > 1) {
        buf.write(n);
      }
    }
    return buf.toString();
  }

  double _molarMass() {
    var mass = 0.0;
    for (final atom in _atoms) {
      final el = allElements.where((e) => e.symbol == atom.symbol);
      if (el.isNotEmpty) {
        mass += el.first.mass;
      }
    }
    return mass;
  }

  _AtomNode? _nearestAtom(Offset p, {double radius = 24}) {
    _AtomNode? best;
    var bestD = double.infinity;
    for (final atom in _atoms) {
      final d = (atom.position - p).distance;
      if (d < radius && d < bestD) {
        best = atom;
        bestD = d;
      }
    }
    return best;
  }

  _BondEdge? _nearestBond(Offset p, {double radius = 14}) {
    _BondEdge? best;
    var bestD = double.infinity;
    for (final bond in _bonds) {
      final a = _atoms.where((x) => x.id == bond.a);
      final b = _atoms.where((x) => x.id == bond.b);
      if (a.isEmpty || b.isEmpty) continue;
      final dist = _distanceToSegment(p, a.first.position, b.first.position);
      if (dist < radius && dist < bestD) {
        best = bond;
        bestD = dist;
      }
    }
    return best;
  }

  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return ap.distance;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / len2).clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  void _addAtomAt(Offset p) {
    final clamped = Offset(
      p.dx.clamp(16, _canvasSize.width - 16),
      p.dy.clamp(16, _canvasSize.height - 16),
    );
    final id = 'a_${DateTime.now().microsecondsSinceEpoch}_${_atoms.length}';
    setState(() {
      _atoms.add(_AtomNode(id: id, symbol: _selectedElement, position: clamped));
      _selectedBondAtomId = null;
    });
    _save();
  }

  void _toggleOrCreateBond(_AtomNode atom, int order) {
    setState(() {
      final firstId = _selectedBondAtomId;
      if (firstId == null) {
        _selectedBondAtomId = atom.id;
        return;
      }
      if (firstId == atom.id) {
        _selectedBondAtomId = null;
        return;
      }

      final existing = _bonds.where(
        (b) => (b.a == firstId && b.b == atom.id) || (b.a == atom.id && b.b == firstId),
      );
      if (existing.isNotEmpty) {
        existing.first.order = order;
      } else {
        _bonds.add(_BondEdge(a: firstId, b: atom.id, order: order));
      }
      _selectedBondAtomId = null;
    });
    _save();
  }

  void _eraseAt(Offset p) {
    final atom = _nearestAtom(p);
    if (atom != null) {
      setState(() {
        _atoms.removeWhere((a) => a.id == atom.id);
        _bonds.removeWhere((b) => b.a == atom.id || b.b == atom.id);
        _selectedBondAtomId = null;
      });
      _save();
      return;
    }
    final bond = _nearestBond(p);
    if (bond != null) {
      setState(() => _bonds.remove(bond));
      _save();
    }
  }

  Future<void> _addLabelAt(Offset p) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141428),
        title: const Text(
          'Add Label',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Label text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    setState(() {
      _labels.add(_ChemLabel(text: value, position: p));
    });
    _save();
  }

  void _addRing({required int sides, required bool aromatic}) {
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2);
    const radius = 80.0;
    final newAtoms = <_AtomNode>[];
    for (var i = 0; i < sides; i++) {
      final angle = (math.pi * 2 * i / sides) - math.pi / 2;
      final id = 'a_${DateTime.now().microsecondsSinceEpoch}_$i';
      newAtoms.add(
        _AtomNode(
          id: id,
          symbol: 'C',
          position: Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          ),
        ),
      );
    }
    setState(() {
      _atoms.addAll(newAtoms);
      for (var i = 0; i < sides; i++) {
        final next = (i + 1) % sides;
        final order = aromatic ? (i.isEven ? 2 : 1) : 1;
        _bonds.add(_BondEdge(a: newAtoms[i].id, b: newAtoms[next].id, order: order));
      }
    });
    _save();
  }

  void _onTapCanvas(Offset p) {
    switch (_tool) {
      case _ChemTool.atom:
        _addAtomAt(p);
        return;
      case _ChemTool.bondSingle:
        final atom = _nearestAtom(p);
        if (atom != null) _toggleOrCreateBond(atom, 1);
        return;
      case _ChemTool.bondDouble:
        final atom = _nearestAtom(p);
        if (atom != null) _toggleOrCreateBond(atom, 2);
        return;
      case _ChemTool.bondTriple:
        final atom = _nearestAtom(p);
        if (atom != null) _toggleOrCreateBond(atom, 3);
        return;
      case _ChemTool.erase:
        _eraseAt(p);
        return;
      case _ChemTool.text:
        _addLabelAt(p);
        return;
      case _ChemTool.select:
      case _ChemTool.markup:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formula = _formulaString();
    final mass = _molarMass();

    return Container(
      constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF38D9A9).withAlpha(70)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolRow(),
          _buildElementRow(),
          _buildSummaryRow(formula, mass),
          const Divider(height: 1, color: Color(0xFF1F1F3A)),
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              width: _canvasSize.width,
              height: _canvasSize.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _onTapCanvas(d.localPosition),
                onPanStart: (d) {
                  if (_tool == _ChemTool.select) {
                    _dragAtomId = _nearestAtom(d.localPosition)?.id;
                  } else if (_tool == _ChemTool.erase) {
                    _eraseAt(d.localPosition);
                  } else if (_tool == _ChemTool.markup) {
                    setState(() {
                      _activeMarkup = _MarkupStroke([d.localPosition]);
                    });
                  }
                },
                onPanUpdate: (d) {
                  if (_tool == _ChemTool.select && _dragAtomId != null) {
                    final atom = _atoms.where((a) => a.id == _dragAtomId);
                    if (atom.isNotEmpty) {
                      setState(() {
                        atom.first.position = Offset(
                          (atom.first.position.dx + d.delta.dx)
                              .clamp(16, _canvasSize.width - 16),
                          (atom.first.position.dy + d.delta.dy)
                              .clamp(16, _canvasSize.height - 16),
                        );
                      });
                    }
                  } else if (_tool == _ChemTool.erase) {
                    _eraseAt(d.localPosition);
                  } else if (_tool == _ChemTool.markup && _activeMarkup != null) {
                    setState(() {
                      _activeMarkup!.points.add(d.localPosition);
                    });
                  }
                },
                onPanEnd: (_) {
                  if (_dragAtomId != null) {
                    _dragAtomId = null;
                    _save();
                  }
                  if (_activeMarkup != null) {
                    final points = _activeMarkup!.points;
                    setState(() {
                      if (points.length >= 2) {
                        _markupStrokes.add(_MarkupStroke(List<Offset>.from(points)));
                      }
                      _activeMarkup = null;
                    });
                    _save();
                  }
                },
                child: CustomPaint(
                  painter: _ChemCanvasPainter(
                    atoms: _atoms,
                    bonds: _bonds,
                    labels: _labels,
                    markupStrokes: _markupStrokes,
                    activeMarkup: _activeMarkup,
                    selectedBondAtomId: _selectedBondAtomId,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _toolChip(_ChemTool.select, 'Select', Icons.open_with_rounded),
          _toolChip(_ChemTool.atom, 'Atom', Icons.add_circle_outline_rounded),
          _toolChip(_ChemTool.bondSingle, 'Bond1', Icons.remove_rounded),
          _toolChip(_ChemTool.bondDouble, 'Bond2', Icons.drag_handle_rounded),
          _toolChip(_ChemTool.bondTriple, 'Bond3', Icons.more_horiz_rounded),
          _toolChip(_ChemTool.text, 'Text', Icons.text_fields_rounded),
          _toolChip(_ChemTool.markup, 'Write', Icons.draw_rounded),
          _toolChip(_ChemTool.erase, 'Erase', Icons.auto_fix_high_rounded),
          _actionChip('Benzene', () => _addRing(sides: 6, aromatic: true)),
          _actionChip('Cyclohex', () => _addRing(sides: 6, aromatic: false)),
          _actionChip('Clear', () {
            setState(() {
              _atoms.clear();
              _bonds.clear();
              _labels.clear();
              _markupStrokes.clear();
            });
            _save();
          }),
        ],
      ),
    );
  }

  Widget _buildElementRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _defaultElements.map((el) {
          final selected = el == _selectedElement;
          return GestureDetector(
            onTap: () => setState(() => _selectedElement = el),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF38D9A9).withAlpha(35)
                    : Colors.white.withAlpha(8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF38D9A9)
                      : Colors.white.withAlpha(20),
                ),
              ),
              child: Text(
                el,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF38D9A9)
                      : Colors.white.withAlpha(180),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow(String formula, double mass) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Row(
        children: [
          Text(
            formula.isEmpty ? 'Formula: -' : 'Formula: $formula',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Atoms: ${_atoms.length}',
            style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 12),
          ),
          const SizedBox(width: 14),
          Text(
            'Mass: ${mass.toStringAsFixed(3)}',
            style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _toolChip(_ChemTool tool, String label, IconData icon) {
    final selected = _tool == tool;
    return GestureDetector(
      onTap: () => setState(() => _tool = tool),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF38D9A9).withAlpha(35)
              : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF38D9A9)
                : Colors.white.withAlpha(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? const Color(0xFF38D9A9) : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? const Color(0xFF38D9A9) : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChemCanvasPainter extends CustomPainter {
  final List<_AtomNode> atoms;
  final List<_BondEdge> bonds;
  final List<_ChemLabel> labels;
  final List<_MarkupStroke> markupStrokes;
  final _MarkupStroke? activeMarkup;
  final String? selectedBondAtomId;

  const _ChemCanvasPainter({
    required this.atoms,
    required this.bonds,
    required this.labels,
    required this.markupStrokes,
    required this.activeMarkup,
    required this.selectedBondAtomId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF101027);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      bg,
    );

    final grid = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    for (final bond in bonds) {
      final a = atoms.where((x) => x.id == bond.a);
      final b = atoms.where((x) => x.id == bond.b);
      if (a.isEmpty || b.isEmpty) continue;
      _drawBond(canvas, a.first.position, b.first.position, bond.order);
    }

    for (final atom in atoms) {
      _drawAtom(canvas, atom, selected: atom.id == selectedBondAtomId);
    }

    for (final label in labels) {
      final tp = TextPainter(
        text: TextSpan(
          text: label.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, label.position);
    }

    final markupPaint = Paint()
      ..color = const Color(0xFFFFD43B)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in markupStrokes) {
      _drawPolyline(canvas, stroke.points, markupPaint);
    }
    if (activeMarkup != null) {
      _drawPolyline(canvas, activeMarkup!.points, markupPaint);
    }
  }

  void _drawPolyline(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawAtom(Canvas canvas, _AtomNode atom, {required bool selected}) {
    final fill = Paint()
      ..color = selected
          ? const Color(0xFF38D9A9).withAlpha(80)
          : const Color(0xFF1F1F3A);
    final stroke = Paint()
      ..color = selected ? const Color(0xFF38D9A9) : Colors.white.withAlpha(55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(atom.position, 15, fill);
    canvas.drawCircle(atom.position, 15, stroke);

    final tp = TextPainter(
      text: TextSpan(
        text: atom.symbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, atom.position - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawBond(Canvas canvas, Offset a, Offset b, int order) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    if (order <= 1) {
      canvas.drawLine(a, b, paint);
      return;
    }
    final dir = b - a;
    final len = dir.distance == 0 ? 1.0 : dir.distance;
    final normal = Offset(-dir.dy / len, dir.dx / len);
    final gap = order == 2 ? 3.2 : 4.4;
    canvas.drawLine(a + normal * gap, b + normal * gap, paint);
    canvas.drawLine(a - normal * gap, b - normal * gap, paint);
    if (order >= 3) {
      canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChemCanvasPainter oldDelegate) {
    return oldDelegate.atoms != atoms ||
        oldDelegate.bonds != bonds ||
        oldDelegate.labels != labels ||
        oldDelegate.markupStrokes != markupStrokes ||
        oldDelegate.activeMarkup != activeMarkup ||
        oldDelegate.selectedBondAtomId != selectedBondAtomId;
  }
}

