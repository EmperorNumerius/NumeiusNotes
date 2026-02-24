import 'package:flutter/material.dart';
import 'package:notes_app/models/quiz.dart';

class QuizStudyPage extends StatefulWidget {
  final QuizSet quizSet;

  const QuizStudyPage({super.key, required this.quizSet});

  @override
  State<QuizStudyPage> createState() => _QuizStudyPageState();
}

class _QuizStudyPageState extends State<QuizStudyPage> {
  int _index = 0;
  final Map<int, int> _answers = {};
  bool _showResults = false;

  @override
  Widget build(BuildContext context) {
    final questions = widget.quizSet.questions;
    final done = _showResults || _index >= questions.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Generated Quiz')),
      body: done ? _buildResults(questions) : _buildQuestion(questions[_index]),
    );
  }

  Widget _buildQuestion(QuizQuestion question) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${_index + 1}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(question.question),
          const SizedBox(height: 16),
          ...List.generate(question.options.length, (optionIndex) {
            return RadioListTile<int>(
              title: Text(question.options[optionIndex]),
              value: optionIndex,
              groupValue: _answers[_index],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _answers[_index] = value);
              },
            );
          }),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_index == widget.quizSet.questions.length - 1) {
                  _showResults = true;
                } else {
                  _index++;
                }
              });
            },
            child: Text(_index == widget.quizSet.questions.length - 1 ? 'Finish' : 'Next'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<QuizQuestion> questions) {
    var correct = 0;
    for (var i = 0; i < questions.length; i++) {
      if (_answers[i] == questions[i].correctAnswerIndex) correct++;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Score: $correct / ${questions.length}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        ...List.generate(questions.length, (i) {
          final q = questions[i];
          final selected = _answers[i];
          final isCorrect = selected == q.correctAnswerIndex;
          return Card(
            child: ListTile(
              title: Text(q.question),
              subtitle: Text('Correct: ${q.options[q.correctAnswerIndex]}\nExplanation: ${q.explanation}'),
              trailing: Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
            ),
          );
        })
      ],
    );
  }
}
