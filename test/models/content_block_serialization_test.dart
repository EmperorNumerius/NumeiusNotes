import 'package:notes_app/models/code_language.dart';
import 'package:notes_app/models/content_block.dart';
import 'package:test/test.dart';

void main() {
  group('ContentBlock Serialization with CodeLanguage', () {
    test('Should serialize CodeLanguage to string', () {
      final block = ContentBlock(
        id: '1',
        type: ContentBlockType.code,
        language: CodeLanguage.javascript,
      );

      final json = block.toJson();
      expect(json['language'], 'javascript');
    });

    test('Should deserialize string to CodeLanguage', () {
      final json = {
        'id': '1',
        'type': 'code',
        'language': 'cpp',
      };

      final block = ContentBlock.fromJson(json);
      expect(block.language, CodeLanguage.cpp);
    });

    test('Should default to python for missing or invalid language', () {
      final jsonMissing = {
        'id': '1',
        'type': 'code',
      };
      final blockMissing = ContentBlock.fromJson(jsonMissing);
      expect(blockMissing.language, CodeLanguage.python);

      final jsonInvalid = {
        'id': '2',
        'type': 'code',
        'language': 'ruby',
      };
      final blockInvalid = ContentBlock.fromJson(jsonInvalid);
      expect(blockInvalid.language, CodeLanguage.python);
    });

    test('CodeLanguage enum properties', () {
        expect(CodeLanguage.python.id, 'python');
        expect(CodeLanguage.javascript.id, 'javascript');
        expect(CodeLanguage.cpp.id, 'cpp');

        expect(CodeLanguage.python.displayName, 'Python');
        expect(CodeLanguage.javascript.displayName, 'JavaScript');
        expect(CodeLanguage.cpp.displayName, 'C++');
    });
  });
}
