import 'dart:io';

void main() {
  var file = File('lib/widgets/calculator_block.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(
    'while (p < i.length && _isDigit(i[p])) p++;',
    'while (p < i.length && _isDigit(i[p])) { p++; }'
  );

  content = content.replaceAll(
    "while (p < i.length && (_isAlpha(i[p]) || _isDigit(i[p]) || i[p] == '_')) p++;",
    "while (p < i.length && (_isAlpha(i[p]) || _isDigit(i[p]) || i[p] == '_')) { p++; }"
  );

  content = content.replaceAll(
    "while (p < i.length && i[p] == ' ') p++;",
    "while (p < i.length && i[p] == ' ') { p++; }"
  );

  file.writeAsStringSync(content);
}
