import 'package:flutter/material.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/document.dart';
import 'package:provider/provider.dart';

class FlashcardReviewPage extends StatefulWidget {
  final List<FlashcardReviewItem> cards;

  const FlashcardReviewPage({super.key, required this.cards});

  static List<FlashcardReviewItem> collectCardsFromDocuments(List<NoteDocument> docs) {
    final result = <FlashcardReviewItem>[];
    for (final doc in docs) {
      for (final block in doc.blocks.where((b) => b.type == ContentBlockType.flashcard)) {
        result.add(FlashcardReviewItem(doc: doc, block: block));
      }
    }
    return result;
  }

  @override
  State<FlashcardReviewPage> createState() => _FlashcardReviewPageState();
}

class _FlashcardReviewPageState extends State<FlashcardReviewPage> {
  int _index = 0;
  bool _showAnswer = false;

  void _goNext() {
    if (widget.cards.isEmpty) return;
    setState(() {
      _index = (_index + 1) % widget.cards.length;
      _showAnswer = false;
    });
  }

  void _goPrev() {
    if (widget.cards.isEmpty) return;
    setState(() {
      _index = (_index - 1 + widget.cards.length) % widget.cards.length;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final docMgr = context.read<DocumentManager>();

    if (widget.cards.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        appBar: AppBar(
          title: const Text('Flashcard Review'),
          backgroundColor: const Color(0xFF0F0F23),
        ),
        body: const Center(
          child: Text('No flashcards found.', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final current = widget.cards[_index];
    final question = current.block.content;
    final answer = (current.block.metadata['answer'] as String?) ?? '';
    final tags = ((current.block.metadata['tags'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final difficulty = (current.block.metadata['difficulty'] as int?) ?? 3;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: const Text('Flashcard Review'),
        backgroundColor: const Color(0xFF0F0F23),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  '${_index + 1} / ${widget.cards.length} · ${current.doc.title}',
                  style: TextStyle(color: Colors.white.withAlpha(170), fontSize: 13),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_showAnswer) {
                        current.block.metadata['reviewCount'] = ((current.block.metadata['reviewCount'] as int?) ?? 0) + 1;
                        current.block.metadata['lastReviewed'] = DateTime.now().toIso8601String();
                        docMgr.saveDocument(current.doc);
                      }
                      setState(() => _showAnswer = !_showAnswer);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _showAnswer
                            ? const Color(0xFF7C3AED).withAlpha(35)
                            : const Color(0xFF00D2FF).withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _showAnswer
                              ? const Color(0xFF7C3AED).withAlpha(100)
                              : const Color(0xFF00D2FF).withAlpha(90),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _showAnswer ? 'Answer' : 'Prompt',
                            style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _showAnswer
                                    ? (answer.isEmpty ? 'No answer yet.' : answer)
                                    : (question.isEmpty ? 'No prompt yet.' : question),
                                style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _chip('Difficulty D$difficulty'),
                              if (tags.isNotEmpty) ...tags.map((t) => _chip('#$t')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _goPrev,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showAnswer = !_showAnswer),
                      icon: const Icon(Icons.flip_rounded),
                      label: Text(_showAnswer ? 'Hide answer' : 'Reveal answer'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _goNext,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: Colors.white.withAlpha(190), fontSize: 11)),
    );
  }
}

class FlashcardReviewItem {
  final NoteDocument doc;
  final ContentBlock block;

  const FlashcardReviewItem({required this.doc, required this.block});
}
