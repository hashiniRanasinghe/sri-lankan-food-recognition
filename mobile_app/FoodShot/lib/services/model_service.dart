// lib/services/model_service.dart
//
// Strategy:
//   1. Try TFLite on-device model (fast, offline)
//   2. If TFLite unavailable → fall back to Hugging Face HTTP API (needs internet)
//   3. If both fail → show clear error, never show a wrong confident label

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'food_recognition_service.dart';
import '../utils/constants.dart';

class ModelService {
  final FoodRecognitionService _foodService = FoodRecognitionService();
  bool _tfliteLoaded = false;
  String? _loadError;

  bool get isLoaded => _tfliteLoaded;
  String? get loadError => _loadError;

  // ─── Hugging Face Inference API ────────────────────────────────────────────
  static const String _hfModel =
      'ranasinghehashini/srilankan-food-recognition';
  static const String _hfApiUrl =
      'https://api-inference.huggingface.co/models/$_hfModel';
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> loadModel() async {
    try {
      await _foodService.initialize();
      _tfliteLoaded = true;
      _loadError = null;
      print('✅ TFLite model service ready');
      return true;
    } catch (e) {
      _loadError = e.toString();
      _tfliteLoaded = false;
      print('⚠️ TFLite not available, will use Hugging Face API: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    if (!_tfliteLoaded) await loadModel();

    if (_tfliteLoaded) {
      try {
        return await _foodService.recognizeFood(imageFile);
      } catch (e) {
        print('❌ TFLite inference error, falling back to HF API: $e');
      }
    }

    return await _recognizeViaHuggingFace(imageFile);
  }

  /// Calls the Hugging Face Inference API with the raw image bytes.
  Future<Map<String, dynamic>> _recognizeViaHuggingFace(File imageFile) async {
    final startTime = DateTime.now();

    try {
      final bytes = await imageFile.readAsBytes();

      final response = await http
          .post(
            Uri.parse(_hfApiUrl),
            headers: {
              'Content-Type': 'application/octet-stream',
              // No auth needed for public models on the free tier.
              // If you make the model private, add:
              // 'Authorization': 'Bearer YOUR_HF_TOKEN',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      final processingMs = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        // HF image-classification pipeline returns:
        // [ {"label": "carrot_raw", "score": 0.87}, ... ]
        final List<dynamic> raw = json.decode(response.body);
        final predictions = raw.cast<Map<String, dynamic>>();

        if (predictions.isEmpty) return _errorResult('Empty response from server');

        final allScores = <String, double>{};
        for (final p in predictions) {
          final label = (p['label'] as String).replaceAll(' ', '_').toLowerCase();
          allScores[label] = (p['score'] as num).toDouble();
        }

        final topLabel = (predictions.first['label'] as String)
            .replaceAll(' ', '_')
            .toLowerCase();
        final topScore = (predictions.first['score'] as num).toDouble();

        // Use the same entropy-based rejection as the TFLite path
        final isFood = _isValidFoodPrediction(allScores, topLabel);

        return {
          'class': topLabel,
          'confidence': topScore,
          'all_scores': allScores,
          'processing_time': processingMs / 1000.0,
          'is_recognized_as_food': isFood,
          'source': 'huggingface_api',
        };
      } else if (response.statusCode == 503) {
        return _errorResult(
            'Model is warming up on server — please wait 20 seconds and try again.');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return _errorResult(
            'API authentication error (${response.statusCode}). '
            'Make sure the model is set to public on Hugging Face.');
      } else {
        return _errorResult('Server error ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      return _errorResult('No internet connection. Connect to Wi-Fi and try again.');
    } on HttpException catch (e) {
      return _errorResult('Network error: ${e.message}');
    } on FormatException {
      return _errorResult('Unexpected response format from server.');
    } catch (e) {
      return _errorResult('Unexpected error: $e');
    }
  }

  /// Entropy-based food/non-food gate — mirrors FoodRecognitionService
  /// so both backends behave identically.
  ///
  /// ln(8) ≈ 2.08 is max entropy for 8 uniform classes.
  /// Real food: entropy ≈ 0.1–1.0   → accepted
  /// Non-food:  entropy ≈ 1.9–2.1   → rejected
  static const double _maxEntropyThreshold = 1.8;

  bool _isValidFoodPrediction(Map<String, double> scores, String topLabel) {
    if (!AppConstants.foodClasses.contains(topLabel)) return false;

    final total = scores.values.fold(0.0, (a, b) => a + b);
    final norm = total > 0 ? scores.map((k, v) => MapEntry(k, v / total)) : scores;

    double entropy = 0.0;
    for (final p in norm.values) {
      if (p > 0) entropy -= p * log(p);
    }

    return entropy <= _maxEntropyThreshold;
  }

  /// Returns a safe error result — UI will show "Not a recognized food"
  /// with the error message, never a wrong confident label.
  Map<String, dynamic> _errorResult(String message) {
    print('⚠️ ModelService error: $message');
    return {
      'class': AppConstants.foodClasses.first,
      'confidence': 0.0,
      'all_scores': <String, double>{},
      'processing_time': 0.0,
      'is_recognized_as_food': false,
      'error': message,
      'source': 'error',
    };
  }

  void dispose() {
    _foodService.dispose();
    _tfliteLoaded = false;
    _loadError = null;
  }
}
