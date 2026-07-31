import 'package:flutter/material.dart';
import 'package:notes_app/controllers/ai_settings_controller.dart';
import 'package:provider/provider.dart';

class AiSettingsDialog extends StatefulWidget {
  const AiSettingsDialog({super.key});

  @override
  State<AiSettingsDialog> createState() => _AiSettingsDialogState();
}

class _AiSettingsDialogState extends State<AiSettingsDialog> {
  final _hfController = TextEditingController();
  final _fallbackKeyController = TextEditingController();
  final _fallbackEndpointController = TextEditingController();
  final _fallbackModelController = TextEditingController();
  final _copilotKeyController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.read<AiSettingsController>();
    _hfController.text = settings.huggingFaceApiKey;
    _fallbackKeyController.text = settings.fallbackApiKey;
    _fallbackEndpointController.text = settings.fallbackEndpoint;
    _fallbackModelController.text = settings.fallbackModel;
    _copilotKeyController.text = settings.copilotApiKey;
  }

  @override
  void dispose() {
    _hfController.dispose();
    _fallbackKeyController.dispose();
    _fallbackEndpointController.dispose();
    _fallbackModelController.dispose();
    _copilotKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AiSettingsController>();

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text('AI Generation Settings'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ignore: deprecated_member_use, strict_raw_type, deprecated_member_use_from_same_package
              DropdownButtonFormField<AiProviderType>(
                initialValue: settings.provider,
                decoration: const InputDecoration(labelText: 'Provider'),
                items: const [
                  DropdownMenuItem(
                    value: AiProviderType.huggingFace,
                    child: Text('Hugging Face (Free tier BYO token)'),
                  ),
                  DropdownMenuItem(
                    value: AiProviderType.copilot,
                    child: Text('GitHub Copilot'),
                  ),
                  DropdownMenuItem(
                    value: AiProviderType.fallback,
                    child: Text('Fallback (Groq/OpenRouter-compatible)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    settings.updateProvider(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              if (settings.provider == AiProviderType.huggingFace) ...[
                TextField(
                  controller: _hfController,
                  decoration: const InputDecoration(
                    labelText: 'Hugging Face API Key',
                  ),
                  obscureText: true,
                ),
              ] else if (settings.provider == AiProviderType.copilot) ...[
                TextField(
                  controller: _copilotKeyController,
                  decoration: const InputDecoration(
                    labelText: 'GitHub Token (with copilot scope)',
                    helperText:
                        'Use a GitHub personal access token with the copilot scope.',
                  ),
                  obscureText: true,
                ),
              ] else ...[
                TextField(
                  controller: _fallbackKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Fallback API Key',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fallbackEndpointController,
                  decoration: const InputDecoration(
                    labelText: 'Fallback Endpoint',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fallbackModelController,
                  decoration: const InputDecoration(
                    labelText: 'Fallback Model',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await settings.updateHuggingFaceApiKey(_hfController.text);
            await settings.updateCopilotApiKey(_copilotKeyController.text);
            await settings.updateFallback(
              apiKey: _fallbackKeyController.text,
              endpoint: _fallbackEndpointController.text,
              model: _fallbackModelController.text,
            );
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
