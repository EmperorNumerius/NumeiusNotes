import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/models/folder.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:notes_app/models/quiz.dart';
import 'package:notes_app/models/flashcard.dart';
import 'package:notes_app/services/study_context_service.dart';

/// Manages documents, folders, persistence, and active tab state.
class DocumentManager extends ChangeNotifier {
  final List<NoteDocument> _documents = [];
  final List<NoteFolder> _folders = [];
  final List<NoteDocument> _openTabs = [];
  int _activeTabIndex = 0;
  final _uuid = const Uuid();

  List<NoteDocument> get documents => _documents;
  List<NoteFolder> get folders => _folders;
  List<NoteDocument> get openTabs => _openTabs;
  int get activeTabIndex => _activeTabIndex;

  NoteDocument? get activeDocument =>
      _openTabs.isNotEmpty && _activeTabIndex < _openTabs.length
      ? _openTabs[_activeTabIndex]
      : null;

  // ─── Initialization ───────────────────────────────────────────

  Future<void> init() async {
    final dir = await _docDir();
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Load folders
    final folderFile = File('${dir.path}/_folders.json');
    if (folderFile.existsSync()) {
      try {
        final list = jsonDecode(await folderFile.readAsString()) as List;
        _folders.addAll(
          list.map((f) => NoteFolder.fromJson(f as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    // Load documents
    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json') && !f.path.endsWith('_folders.json'),
    );
    for (final file in files) {
      try {
        final json = jsonDecode(await file.readAsString());
        _documents.add(NoteDocument.fromJson(json));
      } catch (_) {}
    }

    // Sort by most recently updated
    _documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _migrateLegacyPdfDocuments();

    notifyListeners();
  }

  Future<Directory> _docDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/NotesApp');
  }

  Future<void> _migrateLegacyPdfDocuments() async {
    final root = await _docDir();
    final pdfDir = Directory('${root.path}/pdfs');
    if (!pdfDir.existsSync()) {
      pdfDir.createSync(recursive: true);
    }

    var changed = false;
    for (final doc in _documents) {
      final legacyPath = doc.pdfPath;
      final hasLegacy = legacyPath != null && legacyPath.isNotEmpty;
      if (!hasLegacy && !doc.hasPdf) {
        continue;
      }

      if (doc.pdfWorkingPath != null && doc.pdfWorkingPath!.isNotEmpty) {
        if (doc.pdfPath != doc.pdfWorkingPath) {
          doc.pdfPath = doc.pdfWorkingPath;
          changed = true;
        }
        continue;
      }

      final src = File(legacyPath!);
      if (!src.existsSync()) {
        doc.pdfWorkingPath = legacyPath;
        doc.pdfPath = legacyPath;
        doc.pdfWritebackEnabled = true;
        doc.pdfPageLayoutVersion = 1;
        changed = true;
        continue;
      }

      final id = _uuid.v4();
      final originalPath = '${pdfDir.path}/${id}_original.pdf';
      final workingPath = '${pdfDir.path}/${id}_working.pdf';
      src.copySync(originalPath);
      src.copySync(workingPath);

      doc.pdfOriginalPath = originalPath;
      doc.pdfWorkingPath = workingPath;
      doc.pdfPath = workingPath;
      doc.pdfWritebackEnabled = true;
      doc.pdfPageLayoutVersion = 1;
      changed = true;
    }

    if (changed) {
      for (final doc in _documents) {
        await saveDocument(doc);
      }
    }
  }

  // ─── Folder CRUD ──────────────────────────────────────────────

  NoteFolder createFolder({String? parentId, String name = 'New Folder'}) {
    final folder = NoteFolder(id: _uuid.v4(), name: name, parentId: parentId);
    _folders.add(folder);
    _saveFolders();
    notifyListeners();
    return folder;
  }

  void renameFolder(String folderId, String newName) {
    final f = _folders.firstWhere((f) => f.id == folderId);
    f.name = newName;
    _saveFolders();
    notifyListeners();
  }

  void setFolderSubject(String folderId, String subject) {
    final f = _folders.firstWhere((f) => f.id == folderId);
    f.subject = subject;
    _saveFolders();
    notifyListeners();
  }

  void setFolderColor(String folderId, int colorValue) {
    final f = _folders.firstWhere((f) => f.id == folderId);
    f.colorValue = colorValue;
    _saveFolders();
    notifyListeners();
  }

  void deleteFolder(String folderId) {
    // Move contained notes to root
    for (final doc in _documents.where((d) => d.folderId == folderId)) {
      doc.folderId = null;
      saveDocument(doc);
    }
    // Delete sub-folders recursively
    final children = _folders.where((f) => f.parentId == folderId).toList();
    for (final child in children) {
      deleteFolder(child.id);
    }
    _folders.removeWhere((f) => f.id == folderId);
    _saveFolders();
    notifyListeners();
  }

  List<NoteFolder> getFoldersByParent(String? parentId) =>
      _folders.where((f) => f.parentId == parentId).toList();

  // ─── Document Queries ─────────────────────────────────────────

  List<NoteDocument> getNotesInFolder(String? folderId) =>
      _documents.where((d) => d.folderId == folderId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<NoteDocument> getRecentNotes({int limit = 10}) {
    final sorted = List<NoteDocument>.from(_documents)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted.take(limit).toList();
  }

  List<NoteDocument> getNotesBySubject(String subject) =>
      _documents.where((d) => d.subject == subject).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<NoteDocument> searchNotes(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final ranked = <({NoteDocument doc, int rank})>[];

    for (final d in _documents) {
      final titleMatch = d.title.toLowerCase().contains(q);
      final subjectMatch = d.subject.toLowerCase().contains(q);
      final bodyMatch = d.blocks.any((block) {
        if (block.content.toLowerCase().contains(q)) return true;
        if (block.output.toLowerCase().contains(q)) return true;
        return _metadataStrings(
          block.metadata,
        ).any((value) => value.contains(q));
      });

      if (!titleMatch && !subjectMatch && !bodyMatch) continue;

      final rank = titleMatch
          ? 0
          : subjectMatch
          ? 1
          : 2;
      ranked.add((doc: d, rank: rank));
    }

    ranked.sort((a, b) {
      final rankCompare = a.rank.compareTo(b.rank);
      if (rankCompare != 0) return rankCompare;
      return b.doc.updatedAt.compareTo(a.doc.updatedAt);
    });

    return ranked.map((entry) => entry.doc).toList();
  }

  Iterable<String> _metadataStrings(Map<String, dynamic> metadata) sync* {
    for (final entry in metadata.entries) {
      yield entry.key.toLowerCase();
      yield* _metadataValueStrings(entry.value);
    }
  }

  Iterable<String> _metadataValueStrings(dynamic value) sync* {
    if (value == null) return;
    if (value is String) {
      yield value.toLowerCase();
      return;
    }
    if (value is num || value is bool) {
      yield value.toString().toLowerCase();
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        yield entry.key.toString().toLowerCase();
        yield* _metadataValueStrings(entry.value);
      }
      return;
    }
    if (value is Iterable) {
      for (final item in value) {
        yield* _metadataValueStrings(item);
      }
      return;
    }
    yield value.toString().toLowerCase();
  }

  Set<String> get allSubjects {
    final subjects = <String>{};
    for (final f in _folders) {
      if (f.subject.isNotEmpty) subjects.add(f.subject);
    }
    for (final d in _documents) {
      if (d.subject.isNotEmpty) subjects.add(d.subject);
    }
    return subjects;
  }

  // ─── Document CRUD ────────────────────────────────────────────

  NoteDocument createDocument({
    String? folderId,
    String? pdfPath,
    String? pdfOriginalPath,
    String? pdfWorkingPath,
  }) {
    final resolvedWorking = pdfWorkingPath ?? pdfPath;
    final doc = NoteDocument(
      id: _uuid.v4(),
      title: 'Note ${_documents.length + 1}',
      folderId: folderId,
      pdfPath: resolvedWorking,
      pdfOriginalPath: pdfOriginalPath,
      pdfWorkingPath: resolvedWorking,
      blocks: [ContentBlock(id: _uuid.v4(), type: ContentBlockType.text)],
    );
    _documents.insert(0, doc);
    saveDocument(doc);
    // Open in a tab
    openInTab(doc);
    return doc;
  }

  void moveToFolder(String docId, String? folderId) {
    final doc = _documents.firstWhere((d) => d.id == docId);
    doc.folderId = folderId;
    doc.touch();
    saveDocument(doc);
    notifyListeners();
  }

  void setDocSubject(String docId, String subject) {
    final doc = _documents.firstWhere((d) => d.id == docId);
    doc.subject = subject;
    doc.touch();
    saveDocument(doc);
    notifyListeners();
  }

  void deleteDocument(String docId) {
    _openTabs.removeWhere((d) => d.id == docId);
    _documents.removeWhere((d) => d.id == docId);
    _deleteFile(docId);
    _deleteGeneratedFiles(docId);
    if (_activeTabIndex >= _openTabs.length && _openTabs.isNotEmpty) {
      _activeTabIndex = _openTabs.length - 1;
    }
    notifyListeners();
  }

  // ─── Tab Management ───────────────────────────────────────────

  void openInTab(NoteDocument doc) {
    // Check if already open
    final existingIndex = _openTabs.indexWhere((d) => d.id == doc.id);
    if (existingIndex >= 0) {
      _activeTabIndex = existingIndex;
    } else {
      _openTabs.add(doc);
      _activeTabIndex = _openTabs.length - 1;
    }
    notifyListeners();
  }

  void setActiveTab(int i) {
    if (i >= 0 && i < _openTabs.length) {
      _activeTabIndex = i;
      notifyListeners();
    }
  }

  void closeTab(int index) {
    if (_openTabs.isEmpty) return;
    _openTabs.removeAt(index);
    if (_activeTabIndex >= _openTabs.length && _openTabs.isNotEmpty) {
      _activeTabIndex = _openTabs.length - 1;
    }
    notifyListeners();
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final doc = _openTabs.removeAt(oldIndex);
    _openTabs.insert(newIndex, doc);
    if (_activeTabIndex == oldIndex) {
      _activeTabIndex = newIndex;
    } else if (_activeTabIndex > oldIndex && _activeTabIndex <= newIndex) {
      _activeTabIndex--;
    } else if (_activeTabIndex < oldIndex && _activeTabIndex >= newIndex) {
      _activeTabIndex++;
    }
    notifyListeners();
  }

  void renameDocument(String docId, String newTitle) {
    final doc = _documents.firstWhere((d) => d.id == docId);
    doc.title = newTitle;
    doc.touch();
    saveDocument(doc);
    notifyListeners();
  }

  // ─── Persistence ──────────────────────────────────────────────

  Future<void> saveDocument(NoteDocument doc) async {
    final dir = await _docDir();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('${dir.path}/${doc.id}.json');
    await file.writeAsString(jsonEncode(doc.toJson()));
  }

  Future<void> saveActiveDocument() async {
    if (activeDocument != null) {
      activeDocument!.touch();
      await saveDocument(activeDocument!);
    }
  }

  Future<void> saveQuizSet(QuizSet quizSet) async {
    final file = await _generatedFile(quizSet.sourceDocId, 'quizzes.json');
    final existing = await loadQuizSets(quizSet.sourceDocId);
    final updated = [quizSet, ...existing.where((q) => q.id != quizSet.id)];
    await file!.writeAsString(
      jsonEncode(updated.map((q) => q.toJson()).toList()),
    );
  }

  Future<List<QuizSet>> loadQuizSets(String docId) async {
    final file = await _generatedFile(docId, 'quizzes.json', create: false);
    if (file == null || !file.existsSync()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      return list
          .map((item) => QuizSet.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFlashcardSet(FlashcardSet flashcardSet) async {
    final file = await _generatedFile(
      flashcardSet.sourceDocId,
      'flashcards.json',
    );
    final existing = await loadFlashcardSets(flashcardSet.sourceDocId);
    final updated = [
      flashcardSet,
      ...existing.where((f) => f.id != flashcardSet.id),
    ];
    await file!.writeAsString(
      jsonEncode(updated.map((f) => f.toJson()).toList()),
    );
  }

  Future<List<FlashcardSet>> loadFlashcardSets(String docId) async {
    final file = await _generatedFile(docId, 'flashcards.json', create: false);
    if (file == null || !file.existsSync()) return [];
    try {
      final list = jsonDecode(await file.readAsString()) as List;
      return list
          .map((item) => FlashcardSet.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveFolders() async {
    final dir = await _docDir();
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('${dir.path}/_folders.json');
    await file.writeAsString(
      jsonEncode(_folders.map((f) => f.toJson()).toList()),
    );
  }

  Future<void> _deleteFile(String id) async {
    final dir = await _docDir();
    final file = File('${dir.path}/$id.json');
    if (file.existsSync()) file.deleteSync();
  }

  Future<File?> _generatedFile(
    String docId,
    String fileName, {
    bool create = true,
  }) async {
    final dir = await _generatedDir(docId);
    if (create && !dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    if (!create && !dir.existsSync()) return null;
    return File('${dir.path}/$fileName');
  }

  Future<Directory> _generatedDir(String docId) async {
    final root = await _docDir();
    return Directory('${root.path}/generated/$docId');
  }

  Future<void> _deleteGeneratedFiles(String docId) async {
    final dir = await _generatedDir(docId);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  /// Shared context input for quiz generation across providers.
  StudyContextResult buildQuizGenerationContext({
    NoteDocument? document,
    StudyContextBuildOptions options = const StudyContextBuildOptions(),
  }) {
    final target = document ?? activeDocument;
    if (target == null) {
      return const StudyContextResult(
        preview: '',
        payload: {
          'note': {'id': null, 'title': '', 'subject': ''},
          'sections': [],
        },
      );
    }
    return StudyContextService.build(target, options: options);
  }

  /// Shared context input for flashcard generation across providers.
  StudyContextResult buildFlashcardGenerationContext({
    NoteDocument? document,
    StudyContextBuildOptions options = const StudyContextBuildOptions(),
  }) {
    return buildQuizGenerationContext(document: document, options: options);
  }
}
