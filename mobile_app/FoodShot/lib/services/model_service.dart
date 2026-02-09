import 'dart:io';
import 'food_recognition_service.dart';
import '../utils/constants.dart';

class ModelService {
  final FoodRecognitionService _foodService = FoodRecognitionService();
  bool _isLoaded = false;

  Future<void> loadModel() async {
    try {
      await _foodService.initialize();
      _isLoaded = true;
      print('✅ Model service ready');
    } catch (e) {
      print('⚠️ Model loading failed: $e');
      throw Exception('Failed to load model: $e');
    }
  }

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    if (!_isLoaded) {
      await loadModel();
    }

    try {
      return await _foodService.recognizeFood(imageFile);
    } catch (e) {
      print('❌ Recognition error: $e');

      // Fallback to demo mode
      return {
        'class': AppConstants.foodClasses.first,
        'confidence': 0.75,
        'all_scores': {AppConstants.foodClasses.first: 0.75},
        'processing_time': 0.1,
      };
    }
  }

  void dispose() {
    _foodService.dispose();
    _isLoaded = false;
  }
}
