/// Supported programming languages for code execution and highlighting.
enum CodeLanguage {
  python,
  javascript,
  cpp;

  String get displayName {
    switch (this) {
      case CodeLanguage.python:
        return 'Python';
      case CodeLanguage.javascript:
        return 'JavaScript';
      case CodeLanguage.cpp:
        return 'C++';
    }
  }

  /// Returns the language ID string (lowercase).
  String get id => name;

  /// Returns the CodeLanguage from a string ID, defaulting to python.
  static CodeLanguage fromId(String? id) {
    if (id == null) return CodeLanguage.python;
    try {
      return CodeLanguage.values.byName(id);
    } catch (_) {
      return CodeLanguage.python;
    }
  }
}
