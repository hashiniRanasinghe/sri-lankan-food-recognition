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

  // Normalization constants (from your training)
  static const List<double> MEAN = [0.485, 0.456, 0.406];
  static const List<double> STD = [0.229, 0.224, 0.225];
  static const int INPUT_SIZE = 224;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load TFLite model
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      print('✅ Model loaded');

      // Load prototypes
      final prototypesJson =
          await rootBundle.loadString('assets/prototypes.json');
      final prototypesData =
          json.decode(prototypesJson) as Map<String, dynamic>;
      _prototypes = prototypesData
          .map((key, value) => MapEntry(key, List<double>.from(value)));
      print('✅ Prototypes loaded: ${_prototypes!.length} classes');

      // Load labels
      final labelsText = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsText.split('\n').where((l) => l.isNotEmpty).toList();
      print('✅ Labels loaded: ${_labels!.length} classes');

      // Load model info
      final infoJson = await rootBundle.loadString('assets/model_info.json');
      _modelInfo = json.decode(infoJson);
      print('✅ Model info loaded');

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

      // 1. Load and preprocess image
      final inputTensor = await _preprocessImage(imageFile);

      // 2. Run inference to get embedding
      var outputTensor = List.filled(128, 0.0).reshape([1, 128]);
      _interpreter!.run(inputTensor, outputTensor);

      // 3. Extract embedding and normalize
      List<double> embedding = List<double>.from(outputTensor[0]);
      embedding = _l2Normalize(embedding);

      // 4. Compare with prototypes
      final result = _compareWithPrototypes(embedding);

      final processingTime =
          DateTime.now().difference(startTime).inMilliseconds;

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

  Future<List<List<List<List<double>>>>> _preprocessImage(
      File imageFile) async {
    // Read image
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

    // Convert to float32 tensor with normalization
    // TFLite expects [1, 224, 224, 3] (NHWC format)
    var inputTensor = List.generate(
      1,
      (_) => List.generate(
        INPUT_SIZE,
        (y) => List.generate(
          INPUT_SIZE,
          (x) {
            final pixel = resized.getPixel(x, y);

            // Extract RGB values (0-255)
            final r = pixel.r / 255.0;
            final g = pixel.g / 255.0;
            final b = pixel.b / 255.0;

            // Normalize using ImageNet mean and std
            final rNorm = (r - MEAN[0]) / STD[0];
            final gNorm = (g - MEAN[1]) / STD[1];
            final bNorm = (b - MEAN[2]) / STD[2];

            return [rNorm, gNorm, bNorm];
          },
        ),
      ),
    );

    return inputTensor;
  }

  List<double> _l2Normalize(List<double> vector) {
    double sum = 0.0;
    for (var v in vector) {
      sum += v * v;
    }
    final norm = sqrt(sum);

    if (norm == 0) return vector;

    return vector.map((v) => v / norm).toList();
  }

  Map<String, dynamic> _compareWithPrototypes(List<double> embedding) {
    Map<String, double> distances = {};

    // Calculate cosine similarity (since both are L2 normalized, this is just dot product)
    for (var className in _prototypes!.keys) {
      final prototype = _prototypes![className]!;

      // Cosine similarity
      double similarity = 0.0;
      for (int i = 0; i < embedding.length; i++) {
        similarity += embedding[i] * prototype[i];
      }

      distances[className] = similarity;
    }

    // Find best match
    var sortedEntries = distances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestMatch = sortedEntries.first;

    // Convert similarity to confidence (0-1 range)
    // Cosine similarity is already in [-1, 1], shift to [0, 1]
    final confidence = (bestMatch.value + 1) / 2;

    return {
      'class': bestMatch.key,
      'confidence': confidence,
      'all_scores': Map.fromEntries(
          sortedEntries.take(5).map((e) => MapEntry(e.key, (e.value + 1) / 2))),
    };
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
