import 'package:flutter/material.dart';
import 'package:notes_app/models/flashcard.dart';

class FlashcardStudyPage extends StatefulWidget {
  final FlashcardSet flashcardSet;

  const FlashcardStudyPage({super.key, required this.flashcardSet});

  @override
  State<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends State<FlashcardStudyPage> {
  int _index = 0;
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.flashcardSet.cards[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('Generated Flashcards')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Card ${_index + 1} / ${widget.flashcardSet.cards.length}'),
            const SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showBack = !_showBack),
                child: Card(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _showBack ? card.back : card.front,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _index == 0
                      ? null
                      : () => setState(() {
                            _index--;
                            _showBack = false;
                          }),
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _index == widget.flashcardSet.cards.length - 1
                      ? null
                      : () => setState(() {
                            _index++;
                            _showBack = false;
                          }),
                  child: const Text('Next'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
