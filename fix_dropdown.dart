import 'dart:io';

void main() {
  var file = File('lib/widgets/ai_settings_dialog.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    'value: settings.provider,',
    'initialValue: settings.provider,'
  );
  file.writeAsStringSync(content);
}
