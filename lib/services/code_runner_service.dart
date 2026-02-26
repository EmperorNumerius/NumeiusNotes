import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notes_app/config/app_config.dart';
import 'package:notes_app/models/code_language.dart';

/// Service for executing code snippets on a remote backend.
class CodeRunnerService {
  static final _jsLogRegex = RegExp(r'''console\.log\((.*?)\)''', multiLine: true);
  static final _cppCoutRegex = RegExp(r'''cout\s*<<\s*(.*?)\s*;''', multiLine: true);
  static final _pythonAssignmentRegex = RegExp(r'''^([a-zA-Z_]\w*)\s*=\s*(.+)$''');
  static final _pythonPrintRegex = RegExp(r'''^print\((.*)\)$''');

  static String get baseUrl => AppConfig.endpoints.codeRunnerBaseUrl;
  static bool get useMock => AppConfig.flags.mockCodeExecution;

  /// Execute a code snippet and return the result.
  static Future<CodeResult> execute(String code, CodeLanguage language) async {
    final shouldMock = useMock || baseUrl.isEmpty;
    if (shouldMock) {
      return _mockExecute(code, language);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': language.name,
          'code': code,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return CodeResult(
          stdout: json['stdout'] as String? ?? '',
          stderr: json['stderr'] as String? ?? '',
          exitCode: json['exitCode'] as int? ?? -1,
        );
      } else {
        return CodeResult(
          stdout: '',
          stderr: 'Server error: ${response.statusCode}',
          exitCode: -1,
        );
      }
    } catch (e) {
      return CodeResult(
        stdout: '',
        stderr: 'Connection error: $e',
        exitCode: -1,
      );
    }
  }

  static Future<CodeResult> _mockExecute(String code, CodeLanguage language) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      return CodeResult(stdout: '(no code provided)', stderr: '', exitCode: 0);
    }

    if (language == CodeLanguage.python) {
      return _mockPythonExecute(code);
    }

    if (language == CodeLanguage.javascript) {
      final logRegex = RegExp(r'''console\.log\((.*?)\)''', multiLine: true);
      final logs = logRegex
    if (language == 'javascript') {
      final logs = _jsLogRegex
          .allMatches(code)
          .map((match) => _stripWrappedQuotes((match.group(1) ?? '').trim()))
          .where((line) => line.isNotEmpty)
          .toList();

      return CodeResult(
        stdout: logs.isEmpty ? '(no output)' : logs.join('\n'),
        stderr: '',
        exitCode: 0,
      );
    }

    if (language == CodeLanguage.cpp) {
      final coutRegex = RegExp(r'''cout\s*<<\s*(.*?)\s*;''', multiLine: true);
      final lines = coutRegex
    if (language == 'cpp') {
      final lines = _cppCoutRegex
          .allMatches(code)
          .map((match) => _stripWrappedQuotes((match.group(1) ?? '').trim()))
          .where((line) => line.isNotEmpty)
          .toList();

      return CodeResult(
        stdout: lines.isEmpty ? '[Mock] C++ code parsed. No cout output found.' : lines.join('\n'),
        stderr: '',
        exitCode: 0,
      );
    }

    return CodeResult(
      stdout: '[Mock] Executed ${language.name} code successfully.',
      stderr: '',
      exitCode: 0,
    );
  }

  static CodeResult _mockPythonExecute(String code) {
    final variables = <String, String>{};
    final output = <String>[];

    final lines = code
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'));

    for (final line in lines) {
      final assignment = _pythonAssignmentRegex.firstMatch(line);
      if (assignment != null) {
        final variable = assignment.group(1)!;
        final valueExpr = assignment.group(2)!.trim();
        variables[variable] = _resolvePythonValue(valueExpr, variables);
        continue;
      }

      final printMatch = _pythonPrintRegex.firstMatch(line);
      if (printMatch != null) {
        final expression = printMatch.group(1)?.trim() ?? '';
        final resolved = _resolvePythonValue(expression, variables);
        output.add(resolved);
      }
    }

    return CodeResult(
      stdout: output.isEmpty ? '(no output)' : output.join('\n'),
      stderr: '',
      exitCode: 0,
    );
  }

  static String _resolvePythonValue(String expression, Map<String, String> variables) {
    final raw = expression.trim();
    if (raw.isEmpty) return '';

    if (variables.containsKey(raw)) {
      return variables[raw]!;
    }

    if (raw.contains('+')) {
      final parts = raw.split('+').map((part) => part.trim()).toList();
      return parts.map((part) => _resolvePythonValue(part, variables)).join();
    }

    return _stripWrappedQuotes(raw);
  }

  static String _stripWrappedQuotes(String value) {
    final trimmed = value.trim();
    if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
        (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }
}

class CodeResult {
  final String stdout;
  final String stderr;
  final int exitCode;

  CodeResult({required this.stdout, required this.stderr, required this.exitCode});
}
