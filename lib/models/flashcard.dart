class Flashcard {
  final String front;
  final String back;
  int easeFactor;
  int intervalDays;
  int repetitions;
  DateTime? nextReviewAt;

  Flashcard({
    required this.front,
    required this.back,
    this.easeFactor = 250,
    this.intervalDays = 1,
    this.repetitions = 0,
    this.nextReviewAt,
  });

  Map<String, dynamic> toJson() => {
        'front': front,
        'back': back,
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'repetitions': repetitions,
        'nextReviewAt': nextReviewAt?.toIso8601String(),
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      easeFactor: (json['easeFactor'] as num?)?.toInt() ?? 250,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 1,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.tryParse(json['nextReviewAt'] as String)
          : null,
    );
  }

  bool get isValid => front.trim().isNotEmpty && back.trim().isNotEmpty;
}

class FlashcardSet {
  final String id;
  final String sourceDocId;
  final DateTime createdAt;
  final List<Flashcard> cards;

  FlashcardSet({
    required this.id,
    required this.sourceDocId,
    required this.cards,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceDocId': sourceDocId,
        'createdAt': createdAt.toIso8601String(),
        'cards': cards.map((c) => c.toJson()).toList(),
      };

  factory FlashcardSet.fromJson(Map<String, dynamic> json) {
    return FlashcardSet(
      id: json['id'] as String? ?? '',
      sourceDocId: json['sourceDocId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      cards: (json['cards'] as List?)
              ?.map((item) => Flashcard.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
