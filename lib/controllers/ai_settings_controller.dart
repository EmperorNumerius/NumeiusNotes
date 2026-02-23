import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:notes_app/services/ai_generation_service.dart';
import 'package:notes_app/services/providers/fallback_client.dart';
import 'package:notes_app/services/providers/huggingface_client.dart';

enum AiProviderType { huggingFace, fallback }

class AiSettingsController extends ChangeNotifier {
  static const _providerKey = 'ai_provider';
  static const _hfKey = 'hf_api_key';
  static const _fallbackKey = 'fallback_api_key';
  static const _fallbackEndpointKey = 'fallback_endpoint';
  static const _fallbackModelKey = 'fallback_model';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AiProviderType provider = AiProviderType.huggingFace;
  String huggingFaceApiKey = '';
  String fallbackApiKey = '';
  String fallbackEndpoint = 'https://api.openrouter.ai/api/v1/chat/completions';
  String fallbackModel = 'meta-llama/llama-3.1-8b-instruct:free';

  Future<void> init() async {
    final p = await _storage.read(key: _providerKey);
    if (p == AiProviderType.fallback.name) {
      provider = AiProviderType.fallback;
    }
    huggingFaceApiKey = await _storage.read(key: _hfKey) ?? '';
    fallbackApiKey = await _storage.read(key: _fallbackKey) ?? '';
    fallbackEndpoint = await _storage.read(key: _fallbackEndpointKey) ?? fallbackEndpoint;
    fallbackModel = await _storage.read(key: _fallbackModelKey) ?? fallbackModel;
    notifyListeners();
  }

  Future<void> updateProvider(AiProviderType value) async {
    provider = value;
    await _storage.write(key: _providerKey, value: value.name);
    notifyListeners();
  }

  Future<void> updateHuggingFaceApiKey(String value) async {
    huggingFaceApiKey = value.trim();
    await _storage.write(key: _hfKey, value: huggingFaceApiKey);
    notifyListeners();
  }

  Future<void> updateFallback({
    required String apiKey,
    required String endpoint,
    required String model,
  }) async {
    fallbackApiKey = apiKey.trim();
    fallbackEndpoint = endpoint.trim();
    fallbackModel = model.trim();

    await _storage.write(key: _fallbackKey, value: fallbackApiKey);
    await _storage.write(key: _fallbackEndpointKey, value: fallbackEndpoint);
    await _storage.write(key: _fallbackModelKey, value: fallbackModel);
    notifyListeners();
  }

  AiGenerationService? buildService() {
    if (provider == AiProviderType.huggingFace) {
      if (huggingFaceApiKey.isEmpty) return null;
      return HuggingFaceClient(apiKey: huggingFaceApiKey);
    }

    if (fallbackApiKey.isEmpty || fallbackEndpoint.isEmpty || fallbackModel.isEmpty) {
      return null;
    }

    return FallbackProviderClient(
      apiKey: fallbackApiKey,
      endpoint: fallbackEndpoint,
      model: fallbackModel,
    );
  }
}
