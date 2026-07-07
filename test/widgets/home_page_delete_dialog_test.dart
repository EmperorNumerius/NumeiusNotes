import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:notes_app/controllers/document_manager.dart';
import 'package:notes_app/models/folder.dart';
import 'package:notes_app/models/document.dart';
import 'package:notes_app/widgets/home_page.dart';

class MockDocumentManager extends DocumentManager {
  bool deleteFolderCalled = false;
  String? deletedFolderId;

  bool deleteDocumentCalled = false;
  String? deletedDocumentId;

  MockDocumentManager() {
    folders.add(NoteFolder(id: 'folder1', name: 'Test Folder'));
    documents.add(NoteDocument(id: 'note1', title: 'Test Note'));
  }

  @override
  Future<void> deleteFolder(String id) async {
    deleteFolderCalled = true;
    deletedFolderId = id;
    notifyListeners();
  }

  @override
  Future<void> deleteDocument(String id) async {
    deleteDocumentCalled = true;
    deletedDocumentId = id;
    notifyListeners();
  }
}

void main() {
  testWidgets('Delete folder shows confirmation dialog and functions correctly', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    final mockDocMgr = MockDocumentManager();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DocumentManager>(
            create: (_) => mockDocMgr,
            child: const HomePage(),
          ),
        ),
      ),
    );

    // Wait for everything to settle
    await tester.pumpAndSettle();

    // Find the folder and long press to open menu
    final folderFinder = find.text('Test Folder');
    expect(folderFinder, findsOneWidget);
    await tester.longPress(folderFinder);
    await tester.pumpAndSettle();

    // Find and tap the Delete option in the bottom sheet
    final deleteOption = find.text('Delete');
    expect(deleteOption, findsOneWidget);
    await tester.tap(deleteOption);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('Delete Folder?'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this folder and all its contents?'), findsOneWidget);

    // Tap cancel first to verify it doesn't delete
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    expect(mockDocMgr.deleteFolderCalled, isFalse);
    expect(find.text('Delete Folder?'), findsNothing);

    // Long press again to reopen menu
    await tester.longPress(folderFinder);
    await tester.pumpAndSettle();

    // Tap Delete option again
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Tap confirm this time
    final confirmBtn = find.widgetWithText(TextButton, 'Delete');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify delete was called
    expect(mockDocMgr.deleteFolderCalled, isTrue);
    expect(mockDocMgr.deletedFolderId, 'folder1');

    // Reset screen size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Delete note shows confirmation dialog and functions correctly', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;

    final mockDocMgr = MockDocumentManager();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DocumentManager>(
            create: (_) => mockDocMgr,
            child: const HomePage(),
          ),
        ),
      ),
    );

    // Wait for everything to settle
    await tester.pumpAndSettle();

    // Find the note and long press to open menu
    final noteFinder = find.text('Test Note');
    expect(noteFinder, findsOneWidget);
    await tester.longPress(noteFinder);
    await tester.pumpAndSettle();

    // Find and tap the Delete option in the bottom sheet
    final deleteOption = find.text('Delete');
    expect(deleteOption, findsOneWidget);
    await tester.tap(deleteOption);
    await tester.pumpAndSettle();

    // Verify confirmation dialog appears
    expect(find.text('Delete Note?'), findsOneWidget);
    expect(find.text('Are you sure you want to delete this note?'), findsOneWidget);

    // Tap cancel first to verify it doesn't delete
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();

    expect(mockDocMgr.deleteDocumentCalled, isFalse);
    expect(find.text('Delete Note?'), findsNothing);

    // Long press again to reopen menu
    await tester.longPress(noteFinder);
    await tester.pumpAndSettle();

    // Tap Delete option again
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Tap confirm this time
    final confirmBtn = find.widgetWithText(TextButton, 'Delete');
    expect(confirmBtn, findsOneWidget);
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Verify delete was called
    expect(mockDocMgr.deleteDocumentCalled, isTrue);
    expect(mockDocMgr.deletedDocumentId, 'note1');

    // Reset screen size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
