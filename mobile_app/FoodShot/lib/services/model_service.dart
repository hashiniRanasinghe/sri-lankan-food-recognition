// lib/services/model_service.dart 

import 'dart:io';
import 'food_recognition_service.dart';
import '../utils/constants.dart';

class ModelService {
  final FoodRecognitionService _foodService = FoodRecognitionService();
  bool _isLoaded = false;
  String? _loadError;

  bool get isLoaded => _isLoaded;
  String? get loadError => _loadError;

  Future<bool> loadModel() async {
    try {
      await _foodService.initialize();
      _isLoaded = true;
      _loadError = null;
      print('✅ Model service ready');
      return true;
    } catch (e) {
      _loadError = e.toString();
      _isLoaded = false;
      print('⚠️ Model loading failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    // Auto-load if not loaded yet
    if (!_isLoaded) {
      final loaded = await loadModel();
      if (!loaded) {
        return _getDemoResult();
      }
    }

    try {
      return await _foodService.recognizeFood(imageFile);
    } catch (e) {
      print('❌ Recognition error: $e');
      return _getDemoResult();
    }
  }

  Map<String, dynamic> _getDemoResult() {
    return {
      'class': AppConstants.foodClasses.first,
      'confidence': 0.75,
      'all_scores': {AppConstants.foodClasses.first: 0.75},
      'processing_time': 0.1,
      'is_demo': true, // Flag for demo mode
    };
  }

  void dispose() {
    _foodService.dispose();
    _isLoaded = false;
    _loadError = null;
  }
}
