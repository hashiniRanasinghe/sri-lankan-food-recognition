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

  // ImageNet normalization
  static const List<double> MEAN = [0.485, 0.456, 0.406];
  static const List<double> STD  = [0.229, 0.224, 0.225];
  static const int INPUT_SIZE    = 224;
  static const int EMBEDDING_DIM = 128;

  /// Below this confidence we treat the image as "not recognized as food"
  /// (e.g. non-food images like people, objects) to avoid wrong labels.
  static const double confidenceThreshold = 0.80;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/model.tflite',
        options: options,
      );
      print('✅ Model loaded');

      final prototypesJson =
          await rootBundle.loadString('assets/prototypes.json');
      final prototypesData =
          json.decode(prototypesJson) as Map<String, dynamic>;
      _prototypes = prototypesData.map(
        (key, value) => MapEntry(key, List<double>.from(value as List)),
      );
      print('✅ Prototypes loaded: ${_prototypes!.length} classes');

      final labelsText = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsText
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      print('✅ Labels loaded: ${_labels!.length} classes');

      try {
        final infoJson =
            await rootBundle.loadString('assets/model_info.json');
        _modelInfo = json.decode(infoJson);
        print('✅ Model info loaded');
      } catch (e) {
        print('⚠️ Model info not available: $e');
      }

      _isInitialized = true;
      print('🎉 Food Recognition Service initialized!');
    } catch (e) {
      print('❌ Initialization error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    if (!_isInitialized) await initialize();

    final startTime = DateTime.now();

    // Step 1: Preprocess → [1, 224, 224, 3] NHWC nested list (required by TFLite)
    final inputTensor = await _preprocessImage(imageFile);

    // Step 2: Output buffer [1, 128]
    final output =
        List.generate(1, (_) => List.filled(EMBEDDING_DIM, 0.0));

    // Step 3: Run inference
    _interpreter!.run(inputTensor, output);

    // Step 4: L2-normalise embedding
    final rawEmbedding =
        Float32List.fromList(output[0].map((e) => e.toDouble()).toList());
    final embedding = _l2Normalize(rawEmbedding);

    // Step 5: Nearest prototype → softmax confidence
    final result = _compareWithPrototypes(embedding);

    final processingMs =
        DateTime.now().difference(startTime).inMilliseconds;

    final confidence = result['confidence'] as double;
    return {
      'class': result['class'],
      'confidence': confidence,
      'all_scores': result['all_scores'],
      'processing_time': processingMs / 1000.0,
      'is_recognized_as_food': confidence >= confidenceThreshold,
    };
  }

  /// Builds a [1][H][W][3] nested-list tensor in NHWC format.
  /// TFLite requires this shape — a flat Float32List produces wrong results.
  Future<List<List<List<List<double>>>>> _preprocessImage(
      File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    final resized = img.copyResize(
      image,
      width: INPUT_SIZE,
      height: INPUT_SIZE,
      interpolation: img.Interpolation.linear,
    );

    return List.generate(
      1,
      (_) => List.generate(
        INPUT_SIZE,
        (h) => List.generate(
          INPUT_SIZE,
          (w) {
            final pixel = resized.getPixel(w, h);
            return [
              (pixel.r / 255.0 - MEAN[0]) / STD[0],
              (pixel.g / 255.0 - MEAN[1]) / STD[1],
              (pixel.b / 255.0 - MEAN[2]) / STD[2],
            ];
          },
        ),
      ),
    );
  }

  Float32List _l2Normalize(Float32List vector) {
    double sumSq = 0.0;
    for (final v in vector) sumSq += v * v;
    final norm = sqrt(sumSq);
    if (norm == 0) return vector;
    return Float32List.fromList(vector.map((v) => v / norm).toList());
  }

  /// Cosine similarity of two L2-normalised vectors = dot product.
  /// Softmax (scaled ×10) converts raw similarities to calibrated confidence.
  Map<String, dynamic> _compareWithPrototypes(Float32List embedding) {
    final similarities = <String, double>{};
    for (final entry in _prototypes!.entries) {
      double dot = 0.0;
      final proto = entry.value;
      for (int i = 0; i < embedding.length; i++) {
        dot += embedding[i] * proto[i];
      }
      similarities[entry.key] = dot;
    }

    // Numerically stable softmax with ×10 scale for sharper distribution
    final maxSim = similarities.values.reduce(max);
    final expMap =
        similarities.map((k, v) => MapEntry(k, exp((v - maxSim) * 10)));
    final expSum = expMap.values.reduce((a, b) => a + b);
    final confidenceMap =
        expMap.map((k, v) => MapEntry(k, v / expSum));

    final sorted = confidenceMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'class': sorted.first.key,
      'confidence': sorted.first.value,
      'all_scores': Map<String, double>.fromEntries(sorted.take(5)),
    };
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _prototypes = null;
    _labels = null;
    _modelInfo = null;
    _isInitialized = false;
  }
}
