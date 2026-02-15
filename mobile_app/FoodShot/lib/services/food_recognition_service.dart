// lib/services/food_recognition_service.dart

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:math';

class FoodRecognitionService {
  Interpreter? _interpreter;
  Map<String, List<double>>? _prototypes;
  List<String>? _labels;
  Map<String, dynamic>? _modelInfo;

  bool _isInitialized = false;

  // Normalization constants
  static const List<double> MEAN = [0.485, 0.456, 0.406];
  static const List<double> STD = [0.229, 0.224, 0.225];
  static const int INPUT_SIZE = 224;
  static const int EMBEDDING_DIM = 128;

Future<void> initialize() async
  {
    

    if (_isInitialized) return;

    try {
      // Load model with options for better performance
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/model.tflite',
        options: options,
      );
      print('✅ Model loaded');

      // Load prototypes
      final prototypesJson = await rootBundle.loadString(
        'assets/prototypes.json',
      );
      final prototypesData =
          json.decode(prototypesJson) as Map<String, dynamic>;
      _prototypes = prototypesData.map(
        (key, value) => MapEntry(key, List<double>.from(value)),
      );
      print('✅ Prototypes loaded: ${_prototypes!.length} classes');

      // Load labels
      final labelsText = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsText
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      print('✅ Labels loaded: ${_labels!.length} classes');

      // Load model info (optional - skip if not critical)
      try {
        final infoJson = await rootBundle.loadString('assets/model_info.json');
        _modelInfo = json.decode(infoJson);
        print('✅ Model info loaded');
      } catch (e) {
        print('⚠️ Model info not available: $e');
      }

      _isInitialized = true;
      print('🎉 Food Recognition Service initialized!');
    } catch (e) {
      print('❌ Error initializing service: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final startTime = DateTime.now();

      // 1. Preprocess image efficiently
      final inputTensor = await _preprocessImageOptimized(imageFile);

      // 2. Run inference
      final outputBuffer = Float32List(EMBEDDING_DIM);
      _interpreter!.run(inputTensor, outputBuffer.buffer.asFloat32List());

      // 3. Normalize embedding
      final embedding = _l2Normalize(outputBuffer);

      // 4. Compare with prototypes
      final result = _compareWithPrototypes(embedding);

      final processingTime = DateTime.now()
          .difference(startTime)
          .inMilliseconds;

      return {
        'class': result['class'],
        'confidence': result['confidence'],
        'all_scores': result['all_scores'],
        'processing_time': processingTime / 1000.0,
      };
    } catch (e) {
      print('❌ Recognition error: $e');
      rethrow;
    }
  }

  // OPTIMIZED: Use Float32List directly instead of nested lists
  Future<Float32List> _preprocessImageOptimized(File imageFile) async {
    // Read and decode image
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to 224x224
    final resized = img.copyResize(
      image,
      width: INPUT_SIZE,
      height: INPUT_SIZE,
      interpolation: img.Interpolation.linear,
    );

    // Create flat Float32List (224 * 224 * 3 = 150,528 elements)
    final inputSize = INPUT_SIZE * INPUT_SIZE * 3;
    final inputTensor = Float32List(inputSize);

    var pixelIndex = 0;
    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        final pixel = resized.getPixel(x, y);

        // Extract and normalize RGB
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        // Apply ImageNet normalization
        inputTensor[pixelIndex++] = (r - MEAN[0]) / STD[0];
        inputTensor[pixelIndex++] = (g - MEAN[1]) / STD[1];
        inputTensor[pixelIndex++] = (b - MEAN[2]) / STD[2];
      }
    }

    return inputTensor;
  }

  Float32List _l2Normalize(Float32List vector) {
    double sumSquares = 0.0;
    for (var v in vector) {
      sumSquares += v * v;
    }
    final norm = sqrt(sumSquares);

    if (norm == 0) return vector;

    final normalized = Float32List(vector.length);
    for (int i = 0; i < vector.length; i++) {
      normalized[i] = vector[i] / norm;
    }
    return normalized;
  }

  Map<String, dynamic> _compareWithPrototypes(Float32List embedding) {
    final distances = <String, double>{};

    // Calculate cosine similarity (dot product since normalized)
    for (var entry in _prototypes!.entries) {
      final prototype = entry.value;
      double similarity = 0.0;

      for (int i = 0; i < embedding.length; i++) {
        similarity += embedding[i] * prototype[i];
      }

      distances[entry.key] = similarity;
    }

    // Sort by similarity (descending)
    final sortedEntries = distances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestMatch = sortedEntries.first;

    // Convert similarity [-1, 1] to confidence [0, 1]
    final confidence = (bestMatch.value + 1) / 2;

    return {
      'class': bestMatch.key,
      'confidence': confidence,
      'all_scores': Map.fromEntries(
        sortedEntries.take(5).map((e) => MapEntry(e.key, (e.value + 1) / 2)),
      ),
    };
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _prototypes = null;
    _labels = null;
    _modelInfo = null;
    _isInitialized = false;
  }
}
