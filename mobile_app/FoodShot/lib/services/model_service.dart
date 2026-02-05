// lib/services/model_service.dart

import 'dart:io';
import 'dart:math';
import '../utils/constants.dart';

class ModelService {
  bool _isLoaded = false;
  final Random _random = Random();

  Future<void> loadModel() async {
    // Simulate model loading
    await Future.delayed(const Duration(seconds: 1));
    
    // For now, we'll run in demo mode
    // When your model is trained, we'll add TFLite loading here
    _isLoaded = true;
    
    print('📱 Model Service initialized (Demo Mode)');
  }

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    if (!_isLoaded) {
      throw Exception('Model not loaded');
    }

    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 1500));

    // DEMO MODE: Return random prediction
    // This will be replaced with actual model inference
    final randomIndex = _random.nextInt(AppConstants.foodClasses.length);
    final randomConfidence = 0.65 + _random.nextDouble() * 0.30; // 65-95%

    return {
      'class': AppConstants.foodClasses[randomIndex],
      'confidence': randomConfidence,
      'embedding': List.filled(AppConstants.embeddingDim, 0.0),
    };
  }

  void dispose() {
    // Cleanup when model is integrated
    _isLoaded = false;
  }
}
