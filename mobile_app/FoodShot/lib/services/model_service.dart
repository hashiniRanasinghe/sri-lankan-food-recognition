// lib/services/model_service.dart
//
// ⚠️  The Hugging Face free Inference API no longer supports image-classification
//     models (HTTP 410 "deprecated" as of Feb 2026). There is no free hosted
//     fallback available. All inference is done on-device with TFLite.
//
// On-device pipeline:
//   image → preprocess (224×224, ImageNet normalise) →
//   TFLite embedding (128-dim) → L2-normalise →
//   cosine similarity vs prototypes → entropy-gated softmax → result

import 'dart:io';
import 'food_recognition_service.dart';
import '../utils/constants.dart';

class ModelService {
  final FoodRecognitionService _foodService = FoodRecognitionService();

  bool _tfliteLoaded = false;
  String? _loadError;

  bool get isLoaded    => _tfliteLoaded;
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
      if (!ok) return _tfliteFailResult();
    }

    try {
      final result = await _foodService.recognizeFood(imageFile);
      // Tag result so the UI can show "📱 On-device"
      return {...result, 'source': 'tflite'};
    } catch (e, stack) {
      print('❌ TFLite inference error: $e');
      print(stack);
      return _tfliteFailResult(error: e.toString());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Shown when TFLite itself cannot load or crashes during inference.
  /// Gives the user an actionable message instead of a wrong label.
  Map<String, dynamic> _tfliteFailResult({String? error}) {
    final msg = error != null
        ? 'On-device model error — try restarting the app.\n($error)'
        : 'On-device model could not be loaded.\n'
          'Make sure assets/model.tflite is present in your Flutter assets.';

    print('⚠️  Returning error result: $msg');

    return {
      'class'               : AppConstants.foodClasses.first,
      'confidence'          : 0.0,
      'all_scores'          : <String, double>{},
      'processing_time'     : 0.0,
      'is_recognized_as_food': false,
      'error'               : msg,
      'source'              : 'error',
    };
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  void dispose() {
    _foodService.dispose();
    _tfliteLoaded = false;
    _loadError    = null;
  }
}
