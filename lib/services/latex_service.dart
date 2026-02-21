import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service to convert handwritten strokes to LaTeX.
/// Uses a configurable API endpoint; defaults to mock mode.
class LatexService {
  static bool useMock = true;
  static String apiUrl = 'https://api.mathpix.com/v3/latex'; // placeholder

  /// Convert an image of strokes to LaTeX string.
  /// In mock mode, returns sample LaTeX.
  static Future<String> recognizeLatex(ui.Image image) async {
    if (useMock) {
      return _mockRecognize();
    }

    // Convert image to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return r'\text{Error: could not encode image}';

    final bytes = byteData.buffer.asUint8List();
    final base64Image = base64Encode(bytes);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'src': 'data:image/png;base64,$base64Image',
          'formats': ['latex_simplified'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['latex_simplified'] ?? data['latex'] ?? r'\text{No result}';
      }
      return '\\text{API Error: ${response.statusCode}}';
    } catch (e) {
      return '\\text{Error: $e}';
    }
  }

  static String _mockRecognize() {
    // Return a sample LaTeX expression for testing
    final samples = [
      r'E = mc^2',
      r'\int_{0}^{\infty} e^{-x^2} dx = \frac{\sqrt{\pi}}{2}',
      r'\frac{d}{dx} \sin(x) = \cos(x)',
      r'\sum_{n=1}^{\infty} \frac{1}{n^2} = \frac{\pi^2}{6}',
      r'\nabla \times \mathbf{B} = \mu_0 \mathbf{J} + \mu_0 \epsilon_0 \frac{\partial \mathbf{E}}{\partial t}',
    ];
    return samples[DateTime.now().second % samples.length];
  }
}
