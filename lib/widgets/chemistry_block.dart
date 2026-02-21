import 'package:flutter/material.dart';
import 'package:notes_app/models/periodic_table_data.dart';
import 'package:notes_app/models/content_block.dart';

/// A small record for an element placed in the compound builder.
class _PlacedElement {
  final ChemElement element;
  int subscript;
  bool locked;

  _PlacedElement({required this.element, this.subscript = 1, this.locked = false});

  Map<String, dynamic> toJson() => {
        'atomicNumber': element.atomicNumber,
        'subscript': subscript,
        'locked': locked,
      };

  factory _PlacedElement.fromJson(Map<String, dynamic> json) {
    final el = allElements.firstWhere(
      (e) => e.atomicNumber == json['atomicNumber'],
    );
    return _PlacedElement(
      element: el,
      subscript: json['subscript'] as int? ?? 1,
      locked: json['locked'] as bool? ?? false,
    );
  }
}

/// Interactive chemistry block with periodic table + compound builder.
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
  List<_PlacedElement> _compound = [];
  bool _compoundLocked = false;
  ChemElement? _selectedInfo;
  bool _showTable = true;

  @override
  void initState() {
    super.initState();
    _loadFromMetadata();
  }

  void _loadFromMetadata() {
    final meta = widget.block.metadata;
    if (meta.containsKey('compound')) {
      final list = meta['compound'] as List<dynamic>? ?? [];
      _compound = list
          .map((e) => _PlacedElement.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    _compoundLocked = meta['locked'] as bool? ?? false;
  }

  void _save() {
    widget.block.metadata['compound'] =
        _compound.map((e) => e.toJson()).toList();
    widget.block.metadata['locked'] = _compoundLocked;
    // Update content with formula string
    widget.block.content = _formulaString();
    widget.onChanged();
  }

  String _formulaString() {
    if (_compound.isEmpty) return '';
    final buf = StringBuffer();
    for (final pe in _compound) {
      buf.write(pe.element.symbol);
      if (pe.subscript > 1) buf.write(_subscriptDigits(pe.subscript));
    }
    return buf.toString();
  }

  String _subscriptDigits(int n) {
    const subs = ['₀', '₁', '₂', '₃', '₄', '₅', '₆', '₇', '₈', '₉'];
    return n.toString().split('').map((d) => subs[int.parse(d)]).join();
  }

  void _addElement(ChemElement el) {
    if (_compoundLocked) return;
    setState(() {
      _compound.add(_PlacedElement(element: el));
    });
    _save();
  }

  void _removeElement(int index) {
    if (_compoundLocked) return;
    setState(() {
      _compound.removeAt(index);
    });
    _save();
  }

  void _editSubscript(int index) {
    if (_compoundLocked) return;
    final pe = _compound[index];
    showDialog<int>(
      context: context,
      builder: (ctx) {
        int val = pe.subscript;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text('${pe.element.symbol} subscript',
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          content: StatefulBuilder(
            builder: (_, setB) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, color: Colors.white70),
                  onPressed: val > 1
                      ? () => setB(() => val--)
                      : null,
                ),
                Text('$val',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.white70),
                  onPressed: val < 20
                      ? () => setB(() => val++)
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, val),
              child: const Text('OK', style: TextStyle(color: Color(0xFF00D2FF))),
            ),
          ],
        );
      },
    ).then((newVal) {
      if (newVal != null) {
        setState(() => _compound[index].subscript = newVal);
        _save();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 680, maxHeight: 520),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF38D9A9).withAlpha(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Compound builder bar ──
          _buildCompoundBar(),
          const Divider(height: 1, color: Color(0xFF1F1F3A)),
          // ── Toggle / info ──
          _buildInfoRow(),
          // ── Periodic table or element detail ──
          if (_showTable)
            Flexible(child: _buildPeriodicTable())
          else if (_selectedInfo != null)
            _buildElementDetail(_selectedInfo!),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // COMPOUND BAR
  // ═══════════════════════════════════════════════════════

  Widget _buildCompoundBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.science_rounded,
              size: 16, color: const Color(0xFF38D9A9).withAlpha(180)),
          const SizedBox(width: 6),
          Text('Compound',
              style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          // Placed elements
          Expanded(
            child: _compound.isEmpty
                ? Text('Tap elements to build formula',
                    style: TextStyle(
                        color: Colors.white.withAlpha(30), fontSize: 11, fontStyle: FontStyle.italic))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_compound.length, (i) {
                        final pe = _compound[i];
                        final elColor = categoryColor(pe.element.category);
                        return GestureDetector(
                          onTap: () => _editSubscript(i),
                          onLongPress: () => _removeElement(i),
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: elColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: elColor.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(pe.element.symbol,
                                    style: TextStyle(
                                        color: elColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                if (pe.subscript > 1)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 1),
                                    child: Text(
                                      _subscriptDigits(pe.subscript),
                                      style: TextStyle(color: elColor.withAlpha(180), fontSize: 10),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          // Formula text
          if (_compound.isNotEmpty)
            Text(_formulaString(),
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          // Lock / Unlock
          GestureDetector(
            onTap: () {
              setState(() => _compoundLocked = !_compoundLocked);
              _save();
            },
            child: Tooltip(
              message: _compoundLocked ? 'Unlock compound' : 'Lock compound',
              child: Icon(
                _compoundLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 15,
                color: _compoundLocked
                    ? const Color(0xFFFFD43B)
                    : Colors.white.withAlpha(50),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Clear
          if (_compound.isNotEmpty && !_compoundLocked)
            GestureDetector(
              onTap: () {
                setState(() => _compound.clear());
                _save();
              },
              child: Icon(Icons.clear_rounded,
                  size: 14, color: Colors.white.withAlpha(40)),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // INFO ROW
  // ═══════════════════════════════════════════════════════

  Widget _buildInfoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _showTable = true;
              _selectedInfo = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _showTable ? const Color(0xFF38D9A9).withAlpha(15) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Table',
                  style: TextStyle(
                      color: _showTable ? const Color(0xFF38D9A9) : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          if (_selectedInfo != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _showTable = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: !_showTable ? const Color(0xFF38D9A9).withAlpha(15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_selectedInfo!.name,
                    style: TextStyle(
                        color: !_showTable ? const Color(0xFF38D9A9) : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          const Spacer(),
          // Category legend (small)
          ..._buildLegend(),
        ],
      ),
    );
  }

  List<Widget> _buildLegend() {
    final categories = [
      (ElementCategory.nonmetal, 'Non'),
      (ElementCategory.alkaliMetal, 'Alk'),
      (ElementCategory.transitionMetal, 'Tr'),
      (ElementCategory.nobleGas, 'Nob'),
      (ElementCategory.halogen, 'Hal'),
      (ElementCategory.metalloid, 'Met'),
    ];
    return categories.map((entry) {
      final c = categoryColor(entry.$1);
      return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 2),
            Text(entry.$2,
                style: TextStyle(color: c.withAlpha(150), fontSize: 8)),
          ],
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════
  // PERIODIC TABLE
  // ═══════════════════════════════════════════════════════

  Widget _buildPeriodicTable() {
    // 9 rows × 18 cols grid
    const rows = 10; // 7 main + gap + 2 (lanthanides/actinides)
    const cols = 18;
    const cellSize = 32.0;

    // Build lookup: (row, col) -> element
    final Map<(int, int), ChemElement> lookup = {};
    for (final el in allElements) {
      lookup[(el.row, el.col)] = el;
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(rows, (r) {
              final period = r + 1;
              if (period == 8) {
                // Gap row before lanthanides
                return const SizedBox(height: 6);
              }
              final displayRow = period <= 7 ? period : period;
              return Row(
                children: List.generate(cols, (c) {
                  final group = c + 1;
                  final el = lookup[(displayRow, group)];
                  if (el == null) {
                    return SizedBox(width: cellSize, height: cellSize);
                  }
                  return _elementCell(el, cellSize);
                }),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _elementCell(ChemElement el, double size) {
    final color = categoryColor(el.category);
    return GestureDetector(
      onTap: () {
        _addElement(el);
      },
      onDoubleTap: () {
        setState(() {
          _selectedInfo = el;
          _showTable = false;
        });
      },
      child: Tooltip(
        message: '${el.name} (${el.atomicNumber})',
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withAlpha(40), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${el.atomicNumber}',
                  style: TextStyle(color: color.withAlpha(100), fontSize: 6)),
              Text(el.symbol,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // ELEMENT DETAIL
  // ═══════════════════════════════════════════════════════

  Widget _buildElementDetail(ChemElement el) {
    final color = categoryColor(el.category);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Large symbol
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${el.atomicNumber}',
                    style: TextStyle(color: color.withAlpha(120), fontSize: 10)),
                Text(el.symbol,
                    style: TextStyle(
                        color: color, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(el.name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Atomic Mass: ${el.mass}',
              style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12)),
          Text('Category: ${el.category.name}',
              style: TextStyle(color: color.withAlpha(150), fontSize: 11)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _addElement(el),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add to compound', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withAlpha(25),
              foregroundColor: color,
              side: BorderSide(color: color.withAlpha(60)),
            ),
          ),
        ],
      ),
    );
  }
}
