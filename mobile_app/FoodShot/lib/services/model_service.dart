// lib/services/model_service.dart
//
// Thin orchestration layer over FoodRecognitionService.
// All inference is done on-device via TFLite — no network calls are made.
//
// On-device pipeline (FoodRecognitionService):
//   image → preprocess (224×224, ImageNet normalise) →
//   TFLite embedding (128-dim) → L2-normalise →
//   cosine similarity vs L2-normalised prototypes →
//   entropy-gated softmax → result

import 'dart:io';
import 'food_recognition_service.dart';
import '../utils/constants.dart';

class ModelService {
  final FoodRecognitionService _foodService = FoodRecognitionService();

  bool    _tfliteLoaded = false;
  String? _loadError;

  bool    get isLoaded  => _tfliteLoaded;
  String? get loadError => _loadError;

  // ── Initialise ────────────────────────────────────────────────────────────

  Future<bool> loadModel() async {
    if (_tfliteLoaded) return true;

    try {
      await _foodService.initialize();
      _tfliteLoaded = true;
      _loadError    = null;
      print('✅ TFLite on-device model ready '
            '(${AppConstants.foodClasses.length} classes)');
      return true;
    } catch (e, stack) {
      _loadError    = e.toString();
      _tfliteLoaded = false;
      print('❌ TFLite load failed: $e');
      print(stack);
      return false;
    }
  }

  // ── Inference ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    // Lazy-load on first call
    if (!_tfliteLoaded) {
      final ok = await loadModel();
      if (!ok) return _errorResult();
    }

    try {
      final result = await _foodService.recognizeFood(imageFile);
      return {...result, 'source': 'tflite'};
    } catch (e, stack) {
      print('❌ TFLite inference error: $e');
      print(stack);
      return _errorResult(error: e.toString());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _errorResult({String? error}) {
    final msg = error != null
        ? 'On-device model error — try restarting the app.\n($error)'
        : 'On-device model could not be loaded.\n'
          'Ensure assets/model.tflite is listed in pubspec.yaml.';

    print('⚠️  Returning error result: $msg');

    return {
      'class'                : AppConstants.foodClasses.first,
      'confidence'           : 0.0,
      'all_scores'           : <String, double>{},
      'processing_time'      : 0.0,
      'is_recognized_as_food': false,
      'is_uncertain'         : false,
      'color_hint'           : 'neutral',
      'error'                : msg,
      'source'               : 'error',
    };
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void dispose() {
    _foodService.dispose();
    _tfliteLoaded = false;
    _loadError    = null;
  }
}
