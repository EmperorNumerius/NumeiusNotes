import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:notes_app/config/app_config.dart';

/// Service for executing code snippets on a remote backend.
class CodeRunnerService {
  static String get baseUrl => AppConfig.endpoints.codeRunnerBaseUrl;
  static bool get useMock => AppConfig.flags.mockCodeExecution;

  /// Execute a code snippet and return the result.
  static Future<CodeResult> execute(String code, String language) async {
    final shouldMock = useMock || baseUrl.isEmpty;
    if (shouldMock) {
      return _mockExecute(code, language);
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': language,
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

  static Future<CodeResult> _mockExecute(String code, String language) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (language == 'python') {
      // Simple mock: detect print statements
      final printRegex = RegExp(r'''print\((.*?)\)''');
      final matches = printRegex.allMatches(code);
      final output = matches.map((m) {
        var arg = m.group(1) ?? '';
        // Strip quotes
        if ((arg.startsWith('"') && arg.endsWith('"')) ||
            (arg.startsWith("'") && arg.endsWith("'"))) {
          arg = arg.substring(1, arg.length - 1);
        }
        return arg;
      }).join('\n');
      return CodeResult(stdout: output.isEmpty ? '(no output)' : output, stderr: '', exitCode: 0);
    }

    return CodeResult(
      stdout: '[Mock] Executed $language code successfully.',
      stderr: '',
      exitCode: 0,
    );
  }
}

class CodeResult {
  final String stdout;
  final String stderr;
  final int exitCode;

  CodeResult({required this.stdout, required this.stderr, required this.exitCode});
}
