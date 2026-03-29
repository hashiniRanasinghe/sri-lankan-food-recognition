// lib/services/food_recognition_service.dart
//
// On-device prototypical-network inference pipeline.
// Implements the 10-step pipeline documented in the report (Table 4, Section 5.2.4).
//
// Pipeline:
//   1.  Image acquisition  — File provided by ImagePicker
//   2.  Image decoding     — image package -> pixel-accessible object
//   3.  Orientation fix    — bakeOrientation (EXIF correction)
//   4.  Square centre-crop — largest square crop from centre (preserves aspect ratio)
//   5.  Resize to 224x224  — bilinear interpolation
//   6.  NHWC tensor        — [1][224][224][3], ImageNet-normalised per channel
//   7.  TFLite inference   — 4 CPU threads, output [1][128]
//   8.  L2 normalisation   — produces unit-length embedding vector
//   9.  Cosine similarity  — dot product vs each of 8 L2-normalised stored prototypes
//  10.  Softmax x10        — temperature-scaled calibrated confidence distribution
//
// Out-of-Distribution (OOD) detection:
//   A prototypical network learns to cluster in-distribution images near
//   their class prototypes.  Unrelated images (flowers, faces, objects, etc.)
//   land in empty regions of the embedding space far from every prototype.
//
//   IMPORTANT: Both the query embedding AND the stored prototypes must be
//   L2-normalised before computing dot products.  Only then does
//   dot(emb, proto) == cosine_similarity(emb, proto).
//   Prototypes loaded from prototypes.json are normalised at startup.
//
//   Gate 1 — max cosine similarity (primary, distance-based):
//     If max similarity across all 8 prototypes < _oodDistanceThreshold,
//     the query is treated as OOD.  With normalised prototypes, phone photos
//     often yield max_sim ~0.04–0.15; an old threshold of 0.20 rejected them.
//     See _oodDistanceThreshold (tune using 🔍 max_sim logs).
//
//   Gate 2 — entropy + top confidence (secondary safety net):
//     Very high entropy AND very low top-1 confidence indicate a genuinely
//     uniform distribution.  Thresholds are kept loose so that normal
//     model uncertainty on hard images never causes false rejection.

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:math';

import '../utils/constants.dart';

class FoodRecognitionService {
  Interpreter? _interpreter;
  Map<String, List<double>>? _prototypes;
  List<String>? _labels;
  bool _isInitialized = false;

  // ── Model constants (must match training configuration) ──────────────────

  /// ImageNet normalisation constants — mean and std per RGB channel.
  static const List<double> MEAN = [0.485, 0.456, 0.406];
  static const List<double> STD  = [0.229, 0.224, 0.225];

  /// Input spatial resolution expected by the TFLite model.
  static const int INPUT_SIZE = 224;

  /// Embedding dimensionality output by the prototypical network.
  static const int EMBEDDING_DIM = 128;

  // ── OOD Gate 1 — distance-based threshold ────────────────────────────────

  /// Minimum acceptable maximum cosine similarity across all class prototypes.
  ///
  /// Both query embeddings and stored prototypes are L2-normalised, so
  /// dot(emb, proto) == cosine_similarity exactly.
  ///
  /// Tune using logs: `max_sim` in the 🔍 line.
  ///
  /// Prototypes are **class-mean** embeddings (then L2-normalised). A photo
  /// from the training set is **not** guaranteed to sit at high cosine
  /// similarity to that mean — and centre **square** crop + JPEG/phone pipeline
  /// can push `max_sim` into the 0.02–0.05 range even for valid dishes.
  ///
  /// Gate 1 therefore also checks top softmax mass (see below): if the model
  /// clearly prefers one class above chance (1/8), we do **not** reject on
  /// distance alone — the uncertain UI handles low confidence instead.
  static const double _oodDistanceThreshold = 0.025;

  /// Just above uniform 1/8 (~0.125): visible softmax peak → no distance-only OOD.
  static const double _minTopProbToBypassDistanceOod = 0.129;

  // ── OOD Gate 2 — spread-based threshold (secondary) ─────────────────────

  /// Shannon entropy ceiling above which the softmax is considered near-uniform.
  /// ln(8) ~= 2.079 is the theoretical max.  2.00 only triggers on genuinely
  /// flat distributions.
  static const double _entropyThreshold = 2.00;

  /// Top-1 confidence ceiling.  Only rejects when BOTH entropy AND confidence
  /// conditions are met simultaneously.
  static const double _topProbThreshold = 0.135;

  // ── Uncertainty (UI / viva: no retrain — honest reporting) ───────────────

  /// Below this, the UI must not present a single class as a firm answer.
  static const double uncertainConfidenceCeiling = 0.50;

  /// Above this (nats), the softmax is spread — show top-k, not one label only.
  static const double uncertainEntropyFloor = 1.50;

  /// When the crop looks orange (carrot-like), nudge cosine scores so
  /// `greenbeans_*` does not dominate `carrot_*` on orange curries (no retrain).
  static const double _carrotColourCosineDelta = 0.055;

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/model.tflite',
        options: options,
      );
      print('✅ Model loaded');

      // Load prototypes; normalise key format AND L2-normalise each vector.
      //
      // CRITICAL FIX: prototypes.json stores average embeddings of training
      // samples.  The average of unit vectors is NOT a unit vector — its norm
      // is < 1.  Without explicit normalisation here, dot(unit_embedding, proto)
      // underestimates the true cosine similarity by a factor equal to the
      // prototype norm (0.82–0.99 in the original file).  This caused all
      // similarity scores to fall below the OOD threshold even for correct-class
      // inputs, making the app reject every real food image.
      final prototypesJson =
          await rootBundle.loadString('assets/prototypes.json');
      final prototypesData =
          json.decode(prototypesJson) as Map<String, dynamic>;
      _prototypes = {};
      for (final entry in prototypesData.entries) {
        final key = entry.key.toLowerCase().replaceAll(' ', '_');
        final raw = List<double>.from(entry.value as List);
        _prototypes![key] = _l2NormalizeList(raw); // ← always normalise
      }
      print('✅ Prototypes loaded & normalised: ${_prototypes!.length} classes');

      final labelsText = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsText
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      print('✅ Labels loaded: ${_labels!.length} classes');

      _validatePrototypeBundle();

      try {
        final infoJson =
            await rootBundle.loadString('assets/model_info.json');
        final info = json.decode(infoJson) as Map<String, dynamic>;
        final nc = info['num_classes'];
        if (nc is int && nc != _prototypes!.length) {
          print('⚠️ model_info num_classes ($nc) != prototype count '
                '(${_prototypes!.length})');
        }
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

  // ── Main inference entry point ────────────────────────────────────────────

  Future<Map<String, dynamic>> recognizeFood(File imageFile) async {
    if (!_isInitialized) await initialize();

    final startTime = DateTime.now();

    // Steps 2-4: Decode, fix EXIF orientation, square centre-crop.
    final square = _decodeSquareCrop(await imageFile.readAsBytes());
    final String colorHint = _cropColorHint(square);

    // Steps 5-6: Resize to 224×224 and build the NHWC normalised tensor.
    //
    // CRITICAL: TFLite requires a nested List[1][224][224][3] in channels-last
    // (NHWC) format.  A flat Float32List produces meaningless embeddings
    // because TFLite interprets the channel organisation incorrectly.
    // See report Section 5.2.4, Step 4 for details.
    final inputTensor = _buildNHWCTensor(square);

    // Step 7: TFLite inference -> raw [1][128] embedding.
    final output = List.generate(1, (_) => List.filled(EMBEDDING_DIM, 0.0));
    _interpreter!.run(inputTensor, output);

    // Step 8: Extract and L2-normalise the embedding.
    final rawEmbedding =
        Float32List.fromList(output[0].map((e) => e.toDouble()).toList());
    final embedding = _l2Normalize(rawEmbedding);

    // Step 9: Cosine similarities against all stored prototypes.
    // Both embedding and prototypes are L2-normalised → dot == cosine sim.
    Map<String, double> similarities = _cosineSimilarities(embedding);
    similarities =
        _applyCarrotColourDebias(Map<String, double>.from(similarities), colorHint);

    final double maxSim = similarities.values.reduce(max);

    // Step 10: Temperature-scaled softmax (×10) -> calibrated confidence.
    final confidenceMap = _softmax(similarities);
    final sorted = confidenceMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final String topClass      = sorted.first.key;
    final double topConfidence = sorted.first.value;

    // OOD Gate 1: low max cosine **and** no class favoured above chance.
    // Avoids rejecting valid dishes whose embedding sits modestly far from the
    // mean prototype but still wins the softmax (common for training-set-style
    // photos after crop/compression).
    final bool oodByDistance = maxSim < _oodDistanceThreshold &&
        topConfidence < _minTopProbToBypassDistanceOod;

    // OOD Gate 2: secondary safety net — reject only when distribution is
    // genuinely near-uniform (high entropy AND very low top-1 confidence).
    double entropy = 0.0;
    for (final p in confidenceMap.values) {
      if (p > 0) entropy -= p * log(p);
    }
    final bool oodByEntropy =
        entropy >= _entropyThreshold && topConfidence <= _topProbThreshold;

    // Either gate firing means the image is not a recognised Sri Lankan vegetable.
    final bool isFood = !oodByDistance && !oodByEntropy;

    // In-distribution but unreliable: low top-1 and/or high entropy → top-k UI.
    final bool isUncertain = isFood &&
        (topConfidence < uncertainConfidenceCeiling ||
            entropy > uncertainEntropyFloor);

    final processingMs =
        DateTime.now().difference(startTime).inMilliseconds;

    print('🔍 class=$topClass '
          'conf=${(topConfidence * 100).toStringAsFixed(1)}% '
          'max_sim=${maxSim.toStringAsFixed(3)} '
          'entropy=${entropy.toStringAsFixed(3)} '
          'oodDist=$oodByDistance oodEnt=$oodByEntropy '
          'isFood=$isFood uncertain=$isUncertain');

    return {
      'class'                : topClass,
      'confidence'           : topConfidence,
      'all_scores'           : Map<String, double>.fromEntries(sorted),
      'processing_time'      : processingMs / 1000.0,
      'is_recognized_as_food': isFood,
      'is_uncertain'         : isUncertain,
      'entropy'              : entropy,
      'max_similarity'       : maxSim,
      'color_hint'           : colorHint,
    };
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Decode image bytes, correct EXIF orientation, and return the largest
  /// centred square crop.  Square cropping prevents aspect-ratio distortion
  /// when the image is later resized to the square 224×224 input size.
  img.Image _decodeSquareCrop(Uint8List bytes) {
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    image = img.bakeOrientation(image);
    final w    = image.width;
    final h    = image.height;
    final side = min(w, h);
    final left = (w - side) ~/ 2;
    final topY = (h - side) ~/ 2;
    return img.copyCrop(image, x: left, y: topY, width: side, height: side);
  }

  /// Cheap RGB cue for UI only: carrot-like orange vs green produce vs neither.
  /// Values: `carrot`, `green_veg`, `neutral`.
  String _cropColorHint(img.Image square) {
    double sr = 0, sg = 0, sb = 0;
    var n = 0;
    const step = 8;
    for (var y = 0; y < square.height; y += step) {
      for (var x = 0; x < square.width; x += step) {
        final p = square.getPixel(x, y);
        sr += p.r;
        sg += p.g;
        sb += p.b;
        n++;
      }
    }
    if (n == 0) return 'neutral';
    final r = sr / n;
    final g = sg / n;
    final b = sb / n;
    if (r >= 65 &&
        (r - g) >= 10 &&
        (r - b) >= 6 &&
        g <= r - 4) {
      return 'carrot';
    }
    if (g >= 75 && (g - r) >= 12 && (g - b) >= 8) {
      return 'green_veg';
    }
    return 'neutral';
  }

  /// Resize the square crop to INPUT_SIZE × INPUT_SIZE and build the nested
  /// [1][H][W][3] Float tensor required by TFLite (NHWC channels-last format).
  ///
  /// Uses **ImageNet** normalisation `(pixel/255 − μ) / σ` to match the training
  /// pipeline (same as typical PyTorch/ImageNet pretrain). Using raw `pixel/255`
  /// only would **not** match this checkpoint and would harm embeddings.
  List<List<List<List<double>>>> _buildNHWCTensor(img.Image square) {
    final resized = img.copyResize(
      square,
      width:         INPUT_SIZE,
      height:        INPUT_SIZE,
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
              (pixel.r.toDouble() / 255.0 - MEAN[0]) / STD[0],
              (pixel.g.toDouble() / 255.0 - MEAN[1]) / STD[1],
              (pixel.b.toDouble() / 255.0 - MEAN[2]) / STD[2],
            ];
          },
        ),
      ),
    );
  }

  /// L2-normalise a Float32List so its Euclidean norm equals 1.
  Float32List _l2Normalize(Float32List vector) {
    double sumSq = 0.0;
    for (final v in vector) sumSq += v * v;
    final norm = sqrt(sumSq);
    if (norm < 1e-10) return vector;
    return Float32List.fromList(vector.map((v) => v / norm).toList());
  }

  /// L2-normalise a plain List<double> (used for prototype normalisation
  /// at initialisation time).
  List<double> _l2NormalizeList(List<double> vector) {
    double sumSq = 0.0;
    for (final v in vector) sumSq += v * v;
    final norm = sqrt(sumSq);
    if (norm < 1e-10) return vector;
    return vector.map((v) => v / norm).toList();
  }

  /// Compute cosine similarity between the query embedding and every stored
  /// prototype.  Both are L2-normalised → dot product == cosine similarity.
  Map<String, double> _cosineSimilarities(Float32List embedding) {
    final sims = <String, double>{};
    for (final entry in _prototypes!.entries) {
      double dot = 0.0;
      final proto = entry.value;
      for (int i = 0; i < embedding.length; i++) {
        dot += embedding[i] * proto[i];
      }
      sims[entry.key] = dot;
    }
    return sims;
  }

  /// Numerically stable softmax with temperature scale ×10.
  ///
  /// The ×10 scale sharpens the probability distribution for the narrow
  /// cosine-similarity range (~0.2–0.7) that this 128-dim network produces,
  /// giving confidence scores that meaningfully reflect the gap between the
  /// top prediction and its competitors (report Section 5.2.4).
  ///
  /// Numerical stability: maxSim is subtracted before exponentiation.
  Map<String, double> _softmax(Map<String, double> sims) {
    final maxSim = sims.values.reduce(max);
    final expMap = sims.map((k, v) => MapEntry(k, exp((v - maxSim) * 10)));
    final expSum = expMap.values.reduce((a, b) => a + b);
    return expMap.map((k, v) => MapEntry(k, v / expSum));
  }

  void _validatePrototypeBundle() {
    final expected = AppConstants.foodClasses;
    if (_prototypes!.length != expected.length) {
      print('⚠️ Prototype count ${_prototypes!.length} != expected '
            '${expected.length} (AppConstants.foodClasses)');
    }
    for (final c in expected) {
      if (!_prototypes!.containsKey(c)) {
        print('⚠️ Missing prototype for class id: $c');
      }
    }
    for (final k in _prototypes!.keys) {
      if (!expected.contains(k)) {
        print('⚠️ Extra prototype key (not in AppConstants): $k');
      }
    }
    if (_labels!.length != expected.length) {
      print('⚠️ labels.txt line count ${_labels!.length} != expected '
            '${expected.length}');
    }
    for (final line in _labels!) {
      final id = line.trim();
      if (!_prototypes!.containsKey(id)) {
        print('⚠️ labels.txt "$id" has no matching prototype key');
      }
    }
  }

  /// Orange-dominant crops: reduce known carrot-vs-greenbeans embedding confusion.
  Map<String, double> _applyCarrotColourDebias(
    Map<String, double> sims,
    String colorHint,
  ) {
    if (colorHint != 'carrot') return sims;
    final d = _carrotColourCosineDelta;
    for (final k in sims.keys.toList()) {
      if (k.startsWith('carrot_')) {
        sims[k] = sims[k]! + d;
      } else if (k.startsWith('greenbeans_')) {
        sims[k] = sims[k]! - d;
      }
    }
    return sims;
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _interpreter?.close();
    _interpreter   = null;
    _prototypes    = null;
    _labels        = null;
    _isInitialized = false;
  }
}
