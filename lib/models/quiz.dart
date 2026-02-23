class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correctAnswerIndex': correctAnswerIndex,
        'explanation': explanation,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options: options,
      correctAnswerIndex: (json['correctAnswerIndex'] as num?)?.toInt() ?? -1,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  bool get isValid =>
      question.trim().isNotEmpty &&
      options.length >= 2 &&
      correctAnswerIndex >= 0 &&
      correctAnswerIndex < options.length;
}

class QuizSet {
  final String id;
  final String sourceDocId;
  final DateTime createdAt;
  final List<QuizQuestion> questions;

  QuizSet({
    required this.id,
    required this.sourceDocId,
    required this.questions,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceDocId': sourceDocId,
        'createdAt': createdAt.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory QuizSet.fromJson(Map<String, dynamic> json) {
    return QuizSet(
      id: json['id'] as String? ?? '',
      sourceDocId: json['sourceDocId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      questions: (json['questions'] as List?)
              ?.map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
