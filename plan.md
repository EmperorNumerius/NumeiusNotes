1. **Add `_confirmDelete` method to `lib/widgets/home_page.dart`**:
   - Create a method that shows a confirmation dialog using `AlertDialog` when deleting folders or notes.
   - Example:
     ```dart
     void _confirmDelete({
       required String title,
       required String content,
       required VoidCallback onConfirm,
     }) {
       showDialog(
         context: context,
         builder: (ctx) => AlertDialog(
           backgroundColor: const Color(0xFF1A1A2E),
           title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
           content: Text(content, style: const TextStyle(color: Colors.white70)),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(ctx),
               child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
             ),
             TextButton(
               onPressed: () {
                 Navigator.pop(ctx);
                 onConfirm();
               },
               child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
             ),
           ],
         ),
       );
     }
     ```
2. **Update `_showFolderMenu` in `lib/widgets/home_page.dart`**:
   - Change the `onTap` for the 'Delete' option to use `_confirmDelete`.
3. **Update `_showNoteMenu` in `lib/widgets/home_page.dart`**:
   - Change the `onTap` for the 'Delete' option to use `_confirmDelete`.
4. **Update `test/home_page_folder_dialog_test.dart`**:
   - Add tests to ensure the confirmation dialog appears and works for both deleting folders and notes.
5. **Run tests**:
   - Run `flutter test test/home_page_folder_dialog_test.dart`.
6. **Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.**
7. **Submit the PR**:
   - Commit the changes and submit the PR.
