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

  /// Maximum Shannon entropy (nats) allowed for a valid food prediction.
  ///
  /// When all 8 class scores are nearly equal (flat distribution), the model
  /// has no idea what it's looking at – typical of non-food images like selfies,
  /// objects, or scenes. For 8 uniform classes the maximum entropy is ln(8)≈2.08.
  ///
  /// Calibration (scale ×10 softmax):
  ///   Good Sri Lankan carrot  → entropy ≈ 0.1–0.4  ✅ pass
  ///   Western/roasted carrot  → entropy ≈ 0.7–1.0  ✅ pass
  ///   Face / selfie           → entropy ≈ 2.0+     ❌ reject
  ///   Random object / scene   → entropy ≈ 1.9–2.1  ❌ reject
  static const double maxEntropyThreshold = 1.8;

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
    final allScores = result['all_scores'] as Map<String, double>;

    // Shannon entropy over the full softmax distribution.
    // Peaked distribution (low entropy) = model has a clear best match → food.
    // Flat distribution (high entropy) = model is guessing → not food.
    // We intentionally do NOT gate on raw confidence, because TFLite embeddings
    // can drift from the PyTorch training distribution and real food can score
    // lower absolute confidence while still having a clearly-peaked distribution.
    double entropy = 0.0;
    for (final p in (result['full_scores'] as Map<String, double>).values) {
      if (p > 0) entropy -= p * log(p);
    }

    // Entropy-only decision: ln(8) ≈ 2.079 is the maximum for 8 uniform classes.
    // Threshold of 1.8 leaves a clear gap between real food (~0.1–1.0) and
    // non-food images like faces or random objects (~1.9–2.1).
    final isFood = entropy <= maxEntropyThreshold;

    return {
      'class': result['class'],
      'confidence': confidence,
      'all_scores': allScores,
      'processing_time': processingMs / 1000.0,
      'is_recognized_as_food': isFood,
      'entropy': entropy,
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
      // Full distribution needed for entropy-based rejection
      'full_scores': Map<String, double>.fromEntries(sorted),
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
