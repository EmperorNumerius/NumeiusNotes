import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notes_app/services/ai_generation_service.dart';
import 'package:notes_app/services/providers/copilot_client.dart';
import 'package:notes_app/services/providers/fallback_client.dart';
import 'package:notes_app/services/providers/huggingface_client.dart';

enum AiProviderType { huggingFace, fallback, copilot }

class AiSettingsController extends ChangeNotifier {
  static const _providerKey = 'ai_provider';
  static const _hfKey = 'hf_api_key';
  static const _fallbackKey = 'fallback_api_key';
  static const _fallbackEndpointKey = 'fallback_endpoint';
  static const _fallbackModelKey = 'fallback_model';
  static const _copilotKey = 'copilot_api_key';

  AiProviderType provider = AiProviderType.huggingFace;
  String huggingFaceApiKey = '';
  String fallbackApiKey = '';
  String fallbackEndpoint = 'https://api.openrouter.ai/api/v1/chat/completions';
  String fallbackModel = 'meta-llama/llama-3.1-8b-instruct:free';
  String copilotApiKey = '';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final p = prefs.getString(_providerKey);
    if (p == AiProviderType.fallback.name) {
      provider = AiProviderType.fallback;
    } else if (p == AiProviderType.copilot.name) {
      provider = AiProviderType.copilot;
    }
    huggingFaceApiKey = prefs.getString(_hfKey) ?? '';
    fallbackApiKey = prefs.getString(_fallbackKey) ?? '';
    fallbackEndpoint =
        prefs.getString(_fallbackEndpointKey) ?? fallbackEndpoint;
    fallbackModel = prefs.getString(_fallbackModelKey) ?? fallbackModel;
    copilotApiKey = prefs.getString(_copilotKey) ?? '';
    notifyListeners();
  }

  Future<void> updateProvider(AiProviderType value) async {
    provider = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, value.name);
    notifyListeners();
  }

  Future<void> updateHuggingFaceApiKey(String value) async {
    huggingFaceApiKey = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hfKey, huggingFaceApiKey);
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fallbackKey, fallbackApiKey);
    await prefs.setString(_fallbackEndpointKey, fallbackEndpoint);
    await prefs.setString(_fallbackModelKey, fallbackModel);
    notifyListeners();
  }

  Future<void> updateCopilotApiKey(String value) async {
    copilotApiKey = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_copilotKey, copilotApiKey);
    notifyListeners();
  }

  AiGenerationService? buildService() {
    if (provider == AiProviderType.huggingFace) {
      if (huggingFaceApiKey.isEmpty) return null;
      return HuggingFaceClient(apiKey: huggingFaceApiKey);
    }

    if (provider == AiProviderType.copilot) {
      if (copilotApiKey.isEmpty) return null;
      return CopilotClient(apiKey: copilotApiKey);
    }

    if (fallbackApiKey.isEmpty ||
        fallbackEndpoint.isEmpty ||
        fallbackModel.isEmpty) {
      return null;
    }

    return FallbackProviderClient(
      apiKey: fallbackApiKey,
      endpoint: fallbackEndpoint,
      model: fallbackModel,
    );
  }
}
