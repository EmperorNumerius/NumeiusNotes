import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/widgets/home_page.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/models/folder.dart';
import 'package:provider/provider.dart';

// Minimal mock avoiding file I/O
class MockDocumentManager extends DocumentManager {
  final _testDocs = [
    NoteDocument(
      id: 'doc1',
      title: 'Test Note',
      blocks: [],
      updatedAt: DateTime.now(),
    )
  ];
  final _testFolders = [
    NoteFolder(id: 'folder1', name: 'Test Folder', colorValue: 0xFFFFFFFF)
  ];

  @override
  List<NoteDocument> get documents => _testDocs;

  @override
  List<NoteFolder> get folders => _testFolders;

  @override
  List<NoteDocument> getNotesInFolder(String? id) {
    if (id == null) return _testDocs;
    return [];
  }

  @override
  List<NoteFolder> getFoldersByParent(String? id) {
    if (id == null) return _testFolders;
    return [];
  }

  @override
  Set<String> get allSubjects => {};

  @override
  List<NoteDocument> searchNotes(String query) => [];

  @override
  NoteFolder createFolder({String? parentId, String name = 'New Folder'}) {
    return NoteFolder(id: 'new', name: name);
  }

  @override
  void renameFolder(String folderId, String newName) {}

  @override
  void renameDocument(String docId, String newTitle) {}

  @override
  void deleteFolder(String folderId) {}

  @override
  void deleteDocument(String docId) {}

  @override
  void moveToFolder(String docId, String? folderId) {}
}

void main() {
  testWidgets('HomePage dialogs open and close correctly', (tester) async {
    // Set explicit size for tablet layout to ensure sidebar and main area are visible if needed,
    // though for compact layout (default 800x600 for tests) it might show sidebar in drawer.
    // HomePage uses `constraints.maxWidth < 700` for compact.
    // Default test surface size is 800x600. So it is NOT compact.
    // Sidebar is visible.

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<DocumentManager>(
          create: (_) => MockDocumentManager(),
          child: const HomePage(),
        ),
      ),
    );

    // 1. New Folder Dialog
    final newFolderButton = find.byTooltip('New Folder');
    expect(newFolderButton, findsOneWidget);
    await tester.tap(newFolderButton);
    await tester.pumpAndSettle();

    // Check dialog title
    expect(find.text('New Folder'), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel'), findsNothing);

    // 2. Rename Folder Dialog
    // Long press 'Test Folder'
    final folderCard = find.text('Test Folder');
    expect(folderCard, findsOneWidget);
    await tester.longPress(folderCard);
    await tester.pumpAndSettle();

    // Bottom sheet 'Rename'
    final renameOption = find.text('Rename');
    expect(renameOption, findsOneWidget);
    await tester.tap(renameOption);
    await tester.pumpAndSettle();

    // Dialog should be open
    expect(find.text('Rename Folder'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Rename Folder'), findsNothing);

    // 3. Rename Note Dialog
    // Long press 'Test Note'
    final noteCard = find.text('Test Note');
    expect(noteCard, findsOneWidget);
    await tester.longPress(noteCard);
    await tester.pumpAndSettle();

    // Bottom sheet 'Rename'
    // Note: The bottom sheet for notes also has 'Rename'
    final renameNoteOption = find.text('Rename');
    expect(renameNoteOption, findsOneWidget);
    await tester.tap(renameNoteOption);
    await tester.pumpAndSettle();

    // Dialog should be open
    expect(find.text('Rename Note'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Rename Note'), findsNothing);
  });
}
