import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, staging, prod }

class ServiceEndpoints {
  final String codeRunnerBaseUrl;
  final String latexApiUrl;

  const ServiceEndpoints({
    required this.codeRunnerBaseUrl,
    required this.latexApiUrl,
  });
}

class FeatureFlags {
  final bool mockCodeExecution;
  final bool mockLatexRecognition;

  const FeatureFlags({
    required this.mockCodeExecution,
    required this.mockLatexRecognition,
  });
}

class AppConfig {
  AppConfig._();

  static final AppEnvironment environment = _resolveEnvironment();

  static final ServiceEndpoints endpoints = _resolveEndpoints(environment);

  static final FeatureFlags flags = _resolveFeatureFlags(environment);

  static String get environmentLabel => environment.name.toUpperCase();

  static bool get isExecutionMocked => flags.mockCodeExecution;
  static bool get isLatexMocked => flags.mockLatexRecognition;
  static bool get hasAnyMockingEnabled => isExecutionMocked || isLatexMocked;

  static AppEnvironment _resolveEnvironment() {
    const envValue = String.fromEnvironment('APP_ENV', defaultValue: '');
    switch (envValue.toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.dev;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      default:
        return kReleaseMode ? AppEnvironment.prod : AppEnvironment.dev;
    }
  }

  static ServiceEndpoints _resolveEndpoints(AppEnvironment env) {
    const codeRunnerOverride =
        String.fromEnvironment('CODE_RUNNER_BASE_URL', defaultValue: '');
    const latexOverride = String.fromEnvironment('LATEX_API_URL', defaultValue: '');

    final defaults = switch (env) {
      AppEnvironment.dev => const ServiceEndpoints(
          codeRunnerBaseUrl: 'http://localhost:8080',
          latexApiUrl: 'https://api.mathpix.com/v3/latex',
        ),
      AppEnvironment.staging => const ServiceEndpoints(
          codeRunnerBaseUrl: 'https://staging-code-runner.example.com',
          latexApiUrl: 'https://staging-math.example.com/v3/latex',
        ),
      AppEnvironment.prod => const ServiceEndpoints(
          codeRunnerBaseUrl: 'https://code-runner.example.com',
          latexApiUrl: 'https://math.example.com/v3/latex',
        ),
    };

    final merged = ServiceEndpoints(
      codeRunnerBaseUrl:
          codeRunnerOverride.isNotEmpty ? codeRunnerOverride : defaults.codeRunnerBaseUrl,
      latexApiUrl: latexOverride.isNotEmpty ? latexOverride : defaults.latexApiUrl,
    );

    if (kReleaseMode) {
      return ServiceEndpoints(
        codeRunnerBaseUrl: _sanitizeForRelease(merged.codeRunnerBaseUrl),
        latexApiUrl: _sanitizeForRelease(merged.latexApiUrl),
      );
    }

    return merged;
  }

  static FeatureFlags _resolveFeatureFlags(AppEnvironment env) {
    final defaults = switch (env) {
      AppEnvironment.dev => const FeatureFlags(
          mockCodeExecution: true,
          mockLatexRecognition: true,
        ),
      AppEnvironment.staging => const FeatureFlags(
          mockCodeExecution: false,
          mockLatexRecognition: false,
        ),
      AppEnvironment.prod => const FeatureFlags(
          mockCodeExecution: false,
          mockLatexRecognition: false,
        ),
    };

    return FeatureFlags(
      mockCodeExecution: _resolveBool(
        key: 'MOCK_CODE_EXECUTION',
        fallback: defaults.mockCodeExecution,
      ),
      mockLatexRecognition: _resolveBool(
        key: 'MOCK_LATEX_RECOGNITION',
        fallback: defaults.mockLatexRecognition,
      ),
    );
  }

  static bool _resolveBool({required String key, required bool fallback}) {
    final value = bool.fromEnvironment(key, defaultValue: fallback);
    return value;
  }

  static String _sanitizeForRelease(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('localhost') || lower.contains('127.0.0.1')) {
      return '';
    }
    return url;
  }
}

