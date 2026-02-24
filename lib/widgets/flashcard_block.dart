import 'package:flutter/material.dart';
import 'package:notes_app/models/content_block.dart';

/// Flashcard content block.
///
/// Uses [ContentBlock.content] as the prompt/question.
/// Uses metadata for:
/// - answer: String
/// - tags: List<String>
/// - difficulty: int (1-5)
/// - reviewCount: int
/// - lastReviewed: ISO timestamp String
class FlashcardBlockWidget extends StatefulWidget {
  final ContentBlock block;
  final VoidCallback onChanged;

  const FlashcardBlockWidget({
    super.key,
    required this.block,
    required this.onChanged,
  });

  @override
  State<FlashcardBlockWidget> createState() => _FlashcardBlockWidgetState();
}

class _FlashcardBlockWidgetState extends State<FlashcardBlockWidget> {
  bool _showAnswer = false;

  String get _answer => (widget.block.metadata['answer'] as String?) ?? '';

  List<String> get _tags {
    final raw = widget.block.metadata['tags'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return const [];
  }

  int get _difficulty {
    final raw = widget.block.metadata['difficulty'];
    if (raw is int) return raw.clamp(1, 5);
    if (raw is num) return raw.toInt().clamp(1, 5);
    return 3;
  }

  int get _reviewCount {
    final raw = widget.block.metadata['reviewCount'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  DateTime? get _lastReviewed {
    final raw = widget.block.metadata['lastReviewed'];
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  void _setMetadata(String key, dynamic value) {
    widget.block.metadata[key] = value;
    widget.onChanged();
  }

  void _recordReview() {
    _setMetadata('reviewCount', _reviewCount + 1);
    _setMetadata('lastReviewed', DateTime.now().toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: TextEditingController(text: widget.block.content)
              ..selection = TextSelection.collapsed(offset: widget.block.content.length),
            onChanged: (val) {
              widget.block.content = val;
              widget.onChanged();
            },
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'Prompt',
              labelStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
              hintText: 'Question on the front of the card',
              hintStyle: TextStyle(color: Colors.white.withAlpha(45)),
              filled: true,
              fillColor: Colors.white.withAlpha(4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: TextEditingController(text: _answer)
              ..selection = TextSelection.collapsed(offset: _answer.length),
            onChanged: (val) => _setMetadata('answer', val),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Answer',
              labelStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
              hintText: 'Answer shown when card is flipped',
              hintStyle: TextStyle(color: Colors.white.withAlpha(45)),
              filled: true,
              fillColor: Colors.white.withAlpha(4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(12)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _tags.join(', '))
                    ..selection = TextSelection.collapsed(offset: _tags.join(', ').length),
                  onChanged: (val) {
                    final tags = val
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    _setMetadata('tags', tags);
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Tags (optional)',
                    labelStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
                    hintText: 'biology, chapter-2',
                    hintStyle: TextStyle(color: Colors.white.withAlpha(45), fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withAlpha(4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withAlpha(12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withAlpha(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<int>(
                  initialValue: _difficulty,
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('D${i + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) _setMetadata('difficulty', val);
                  },
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF1A1A2E),
                  decoration: InputDecoration(
                    labelText: 'Difficulty',
                    labelStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withAlpha(4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withAlpha(12)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withAlpha(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              final wasShowingAnswer = _showAnswer;
              setState(() => _showAnswer = !_showAnswer);
              if (!wasShowingAnswer) {
                _recordReview();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _showAnswer ? const Color(0xFF7C3AED).withAlpha(35) : const Color(0xFF00D2FF).withAlpha(22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _showAnswer
                      ? const Color(0xFF7C3AED).withAlpha(80)
                      : const Color(0xFF00D2FF).withAlpha(80),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _showAnswer
                      ? (_answer.isEmpty ? 'No answer yet.' : _answer)
                      : (widget.block.content.isEmpty ? 'No prompt yet.' : widget.block.content),
                  key: ValueKey(_showAnswer),
                  style: const TextStyle(color: Colors.white, height: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _showAnswer ? 'Tap card to show prompt' : 'Tap card to reveal answer',
                style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11),
              ),
              const Spacer(),
              Text(
                'Reviews: $_reviewCount',
                style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11),
              ),
              if (_lastReviewed != null) ...[
                const SizedBox(width: 10),
                Text(
                  'Last: ${_lastReviewed!.year}-${_lastReviewed!.month.toString().padLeft(2, '0')}-${_lastReviewed!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.white.withAlpha(90), fontSize: 11),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
