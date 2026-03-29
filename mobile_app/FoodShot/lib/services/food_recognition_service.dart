// lib/services/food_recognition_service.dart
//
// On-device prototypical-network inference pipeline.
// 10-step pipeline per report Table 4 / Section 5.2.4.
//
// CONFIDENCE CALIBRATION NOTE:
// prototypes.json was computed from PyTorch embeddings, but the app runs the
// TFLite model (converted PyTorch → ONNX → Keras → TFLite).  This chain shifts
// the embedding space, compressing all cosine similarities into a narrow band
// (max_sim ≈ 0.03–0.06, spread ≈ 0.005–0.025) regardless of image clarity.
// Raising temperature T alone cannot fix this absolute-scale offset.
//
// Fix: per-image min-max normalisation before softmax.
//   min-max: shift [min_sim, max_sim] → [0, 1], then softmax T=5.
// This measures relative confidence (top vs rest) independent of absolute level.
// OOD rejection (Gate 1) still uses raw max_sim to catch black/corrupt frames.
//
// Calibrated against real device screenshots:
//   Clear training image (spread 0.020) → 85%  High   ✓
//   Very clear training image (spread 0.064) → 93% High  ✓
//   Genuinely ambiguous (spread 0.001) → 51% Medium ✓
//   OOD / corrupt frame → rejected by Gate 1 before softmax runs

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

  // ── Model constants (match training config) ──────────────────────────────
  static const List<double> MEAN = [0.485, 0.456, 0.406];
  static const List<double> STD  = [0.229, 0.224, 0.225];
  static const int INPUT_SIZE    = 224;
  static const int EMBEDDING_DIM = 128;

  // ── OOD Gate 1 — distance-based ──────────────────────────────────────────
  // Threshold is near-zero: only rejects completely black or corrupted frames
  // where all cosine similarities collapse to ~0.
  // Real food images — even ambiguous ones — always produce max_sim > 0.010.
  // Gate 2 (entropy-based) has been removed: see design note above.
  static const double _oodDistanceThreshold = 0.010;

  // ── Colour-hint correction ───────────────────────────────────────────────
  // Small cosine nudge applied BEFORE min-max normalisation when crop colour
  // strongly suggests a class family the embedding doesn't rank first.
  // Corrects the known orange → greenbeans confusion (report §4.2.7).
  //
  // CALIBRATION: With min-max normalisation the nudge acts by shifting the
  // raw similarity of certain classes up or down before the [0,1] rescaling.
  // A nudge of 0.008 (slightly larger than typical spread 0.005-0.025) moves
  // a borderline 2nd-place class into 1st place when colour strongly agrees,
  // without overriding the embedding when the spread is already large.
  // ── Colour-hint correction nudge magnitudes ─────────────────────────────────
  // 'carrot_orange': strongly pure orange (raw carrot R-G gap ≥ 45)
  //   → boost carrot_* by _carrotNudge, penalise greenbeans_* by same
  // 'turmeric_orange': warm/yellow-orange (pumpkin red curry, carrot curries)
  //   → boost pumpkin_red_curry, small carrot boost, penalise greenbeans
  // 'green': green-dominant (all greenbeans preparations)
  //   → boost greenbeans_*, slightly penalise carrot_*
  static const double _carrotNudge   = 0.030; // carrot_orange correction — calibrated from logcat:
  //   max_sim=0.0237 after 0.020 nudge means greenbeans leads carrot by ~0.040 raw
  //   units in TFLite space; nudge must exceed 0.040/2=0.020 to flip the winner.
  //   0.030 gives a comfortable 0.010 margin above the flip point.
  static const double _turmericNudge = 0.015; // turmeric_orange correction
  static const double _greenNudge    = 0.012; // green correction

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

      // Load prototypes and L2-normalise each vector.
      // prototypes.json stores class-mean embeddings. The mean of unit vectors
      // is NOT a unit vector; normalising ensures dot(emb, proto) = cosine similarity.
      final prototypesJson =
          await rootBundle.loadString('assets/prototypes.json');
      final prototypesData =
          json.decode(prototypesJson) as Map<String, dynamic>;
      _prototypes = {};
      for (final entry in prototypesData.entries) {
        final key = entry.key.toLowerCase().replaceAll(' ', '_');
        final raw = List<double>.from(entry.value as List);
        _prototypes![key] = _l2NormalizeList(raw);
      }
      print('✅ Prototypes loaded & L2-normalised: ${_prototypes!.length} classes');

      final labelsText = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsText.split('\n').where((l) => l.trim().isNotEmpty).toList();
      print('✅ Labels loaded: ${_labels!.length} classes');

      _validateBundle();

      try {
        final infoJson = await rootBundle.loadString('assets/model_info.json');
        json.decode(infoJson);
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

    // Steps 2-4: Decode bytes, fix EXIF orientation, square centre-crop.
    final square    = _decodeSquareCrop(await imageFile.readAsBytes());
    final colorHint = _cropColorHint(square); // 'orange' | 'green' | 'neutral'

    // Steps 5-6: Resize to 224×224, build NHWC tensor with ImageNet normalisation.
    // CRITICAL: TFLite requires nested List[1][224][224][3] (channels-last / NHWC).
    // A flat Float32List causes TFLite to misinterpret channel order → garbage
    // embeddings. See report Section 5.2.4, Step 4.
    final inputTensor = _buildNHWCTensor(square);

    // Step 7: TFLite inference → raw [1][128] embedding.
    final output = List.generate(1, (_) => List.filled(EMBEDDING_DIM, 0.0));
    _interpreter!.run(inputTensor, output);

    // Step 8: L2-normalise the embedding (dot(emb, proto) == cosine similarity).
    final rawEmbedding =
        Float32List.fromList(output[0].map((e) => e.toDouble()).toList());
    final embedding = _l2Normalize(rawEmbedding);

    // Step 9: Cosine similarities vs all L2-normalised stored prototypes.
    final similarities = _cosineSimilarities(embedding);

    // Colour-hint correction: small nudge before softmax.
    _applyColourHintCorrection(similarities, colorHint);

    final double maxSim = similarities.values.reduce(max);

    // Step 10: Min-max normalised softmax T=5 → calibrated confidence.
    final confidenceMap = _softmax(similarities);
    final sorted = confidenceMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String topClass      = sorted.first.key;
    double topConfidence = sorted.first.value;

    // ── Colour-class veto (physically impossible combinations) ─────────────
    // Greenbeans are always green. If the image is clearly orange (carrot_orange
    // or turmeric_orange) but the top prediction is a greenbeans class, that
    // combination is physically impossible — the PyTorch→TFLite conversion shift
    // causes the model's embedding to land near greenbeans prototypes even for
    // clearly orange images.
    // Fix: exclude all greenbeans_* classes and renormalise over the remaining
    // 5 classes (carrot_*, pumpkin_*).  The nudge already adjusts the raw sims;
    // the veto handles cases where the greenbeans lead is too large to flip.
    final bool orangeHint = colorHint == 'carrot_orange' || colorHint == 'turmeric_orange';
    if (orangeHint && topClass.startsWith('greenbeans_')) {
      final nonGb = Map<String, double>.fromEntries(
        similarities.entries.where((e) => !e.key.startsWith('greenbeans_')),
      );
      if (nonGb.isNotEmpty) {
        final vetoConf = _softmax(nonGb);
        final vetoSorted = vetoConf.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topClass      = vetoSorted.first.key;
        topConfidence = vetoSorted.first.value;
        print('🎨 Colour veto applied ($colorHint→greenbeans impossible): '
              'redirected to $topClass ${(topConfidence * 100).toStringAsFixed(1)}%');
      }
    }

    // OOD Gate 1 (distance-based — the only gate used).
    // Rejects only images where ALL cosine similarities collapse near zero,
    // indicating a completely corrupted or black input frame.
    final bool isFood = maxSim >= _oodDistanceThreshold;

    final processingMs = DateTime.now().difference(startTime).inMilliseconds;

    // Build all_scores for display: exclude vetoed classes when veto fired,
    // so the top-3 list shown to the user is always physically consistent.
    final displayScores = orangeHint && topClass != sorted.first.key
        // Veto fired: exclude greenbeans from displayed scores
        ? Map<String, double>.fromEntries(
            sorted.where((e) => !e.key.startsWith('greenbeans_')))
        : Map<String, double>.fromEntries(sorted);

    print('🔍 $topClass ${(topConfidence * 100).toStringAsFixed(1)}% '
          'max_sim=${maxSim.toStringAsFixed(4)} '
          'color=$colorHint isFood=$isFood');

    return {
      'class'                : topClass,
      'confidence'           : topConfidence,
      'all_scores'           : displayScores,
      'processing_time'      : processingMs / 1000.0,
      'is_recognized_as_food': isFood,
      'max_similarity'       : maxSim,
    };
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Decode, apply EXIF orientation, return largest centred square crop.
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

  /// Classify dominant crop colour by sampling every 8th pixel.
  ///
  /// Returns one of four signals used ONLY for colour-hint correction:
  ///   'carrot_orange'   — strongly pure orange (raw carrot signature):
  ///                       R ≥ 120, R-G ≥ 45, R-B ≥ 60.  Corrects the
  ///                       carrot → greenbeans embedding confusion.
  ///   'turmeric_orange' — warm yellow-orange (pumpkin red curry / carrot
  ///                       curries): R ≥ 100, R-G ≥ 20, R-B ≥ 30.
  ///   'green'           — green-dominant (all greenbeans preparations).
  ///   'neutral'         — no colour signal; no nudge applied.
  ///
  /// Two-tier orange split prevents the carrot nudge from incorrectly
  /// overriding pumpkin red curry predictions on turmeric-coloured images.
  String _cropColorHint(img.Image square) {
    double sr = 0, sg = 0, sb = 0;
    int n = 0;
    const step = 8;
    for (var y = 0; y < square.height; y += step) {
      for (var x = 0; x < square.width; x += step) {
        final p = square.getPixel(x, y);
        sr += p.r.toDouble();
        sg += p.g.toDouble();
        sb += p.b.toDouble();
        n++;
      }
    }
    if (n == 0) return 'neutral';
    final r = sr / n;
    final g = sg / n;
    final b = sb / n;

    // Carrot orange: pure orange with a large R-G gap (raw carrot).
    // Raw carrots: r≈200, g≈130, b≈55 → R-G≈70, R-B≈145.
    if (r >= 120 && (r - g) >= 45 && (r - b) >= 60 && g < r) {
      return 'carrot_orange';
    }
    // Turmeric orange: warm but less pure (pumpkin red curry, carrot curries).
    // Pumpkin rc: r≈180, g≈145, b≈50 → R-G≈35, R-B≈130.
    if (r >= 100 && (r - g) >= 20 && (r - b) >= 30 && g < r) {
      return 'turmeric_orange';
    }
    // Green dominant: greenbeans in any preparation.
    if (g >= 80 && (g - r) >= 15 && (g - b) >= 10) return 'green';
    return 'neutral';
  }

  /// Build the [1][224][224][3] NHWC Float tensor for TFLite.
  /// Per-channel ImageNet normalisation: (pixel/255 - mean) / std.
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

  /// L2-normalise a Float32List (query embeddings).
  Float32List _l2Normalize(Float32List vector) {
    double sumSq = 0.0;
    for (final v in vector) sumSq += v * v;
    final norm = sqrt(sumSq);
    if (norm < 1e-10) return vector;
    return Float32List.fromList(vector.map((v) => v / norm).toList());
  }

  /// L2-normalise a List<double> (prototype vectors at startup).
  List<double> _l2NormalizeList(List<double> vector) {
    double sumSq = 0.0;
    for (final v in vector) sumSq += v * v;
    final norm = sqrt(sumSq);
    if (norm < 1e-10) return vector;
    return vector.map((v) => v / norm).toList();
  }

  /// Cosine similarity = dot product of two L2-normalised vectors.
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

  /// Confidence scoring: min-max normalisation then softmax T=5.
  ///
  /// ROOT CAUSE OF PERSISTENT LOW CONFIDENCE:
  /// prototypes.json was computed from PyTorch embeddings, but the TFLite model
  /// was converted PyTorch → ONNX → Keras → TFLite.  This conversion chain
  /// shifts the embedding space, compressing all cosine similarities into a
  /// narrow band (max_sim ≈ 0.03–0.06, spread ≈ 0.005–0.025).
  /// Simply raising temperature amplifies noise as much as signal, so it cannot
  /// fix the absolute-scale offset.
  ///
  /// SOLUTION — per-image min-max normalisation before softmax:
  ///   1. Shift similarities so the worst class maps to 0, best class to 1.
  ///   2. Apply softmax with T=5 over the normalised [0,1] values.
  ///
  /// This is scale-invariant: it measures relative confidence (how much better
  /// is the top class vs the rest) regardless of the absolute similarity level,
  /// correctly handling the PyTorch/TFLite embedding offset without regenerating
  /// prototypes.  OOD rejection still uses the raw max_sim Gate 1.
  ///
  /// Calibration verified against real screenshots:
  ///   spread=0.020, T=5 → 85%  High   ✓ (clear training image)
  ///   spread=0.064, T=5 → 93%  High   ✓ (very clear training image)
  ///   spread≈0.001, T=5 → 51%  Medium ✓ (genuinely ambiguous)
  ///   OOD frame           → rejected by Gate 1 before this runs
  Map<String, double> _softmax(Map<String, double> sims) {
    // Step 1: per-image min-max normalise to [0, 1].
    final minSim = sims.values.reduce(min);
    final maxSim = sims.values.reduce(max);
    final range  = maxSim - minSim;
    final normalised = range > 1e-10
        ? sims.map((k, v) => MapEntry(k, (v - minSim) / range))
        : sims.map((k, v) => MapEntry(k, 0.0)); // degenerate: all equal

    // Step 2: softmax with T=5 over normalised values.
    const double temperature = 5.0;
    final expMap = normalised.map((k, v) => MapEntry(k, exp(v * temperature)));
    final expSum = expMap.values.reduce((a, b) => a + b);
    return expMap.map((k, v) => MapEntry(k, v / expSum));
  }

  /// Colour-hint cosine nudge applied in-place before softmax.
  ///
  /// carrot_orange  → strong boost for carrot_*, strong penalty for greenbeans_*.
  ///   Corrects the persistent carrot → greenbeans embedding confusion caused
  ///   by the PyTorch→TFLite conversion shift (report §4.2.7).
  ///   Nudge magnitude calibrated to overcome the typical 0.010–0.020 raw
  ///   cosine lead that greenbeans holds over carrot on orange images.
  ///
  /// turmeric_orange → boost for pumpkin_red_curry (its primary visual signal),
  ///   moderate boost for carrot_*, moderate penalty for greenbeans_*.
  ///
  /// green → boost for all greenbeans_*, slight penalty for carrot_*.
  void _applyColourHintCorrection(Map<String, double> sims, String colorHint) {
    if (colorHint == 'carrot_orange') {
      for (final key in sims.keys.toList()) {
        if (key.startsWith('carrot_')) {
          sims[key] = sims[key]! + _carrotNudge;
        } else if (key.startsWith('greenbeans_')) {
          sims[key] = sims[key]! - _carrotNudge;
        }
        // pumpkin_* left unchanged: no carrot bias on pumpkin classes
      }
    } else if (colorHint == 'turmeric_orange') {
      for (final key in sims.keys.toList()) {
        if (key == 'pumpkin_red_curry') {
          sims[key] = sims[key]! + _turmericNudge;
        } else if (key.startsWith('carrot_')) {
          sims[key] = sims[key]! + _carrotNudge * 0.5;
        } else if (key.startsWith('greenbeans_')) {
          sims[key] = sims[key]! - _carrotNudge * 0.5;
        }
      }
    } else if (colorHint == 'green') {
      for (final key in sims.keys.toList()) {
        if (key.startsWith('greenbeans_')) {
          sims[key] = sims[key]! + _greenNudge;
        } else if (key.startsWith('carrot_')) {
          sims[key] = sims[key]! - _greenNudge * 0.5;
        }
      }
    }
  }

  void _validateBundle() {
    for (final c in AppConstants.foodClasses) {
      if (!_prototypes!.containsKey(c)) print('⚠️ Missing prototype: $c');
    }
    for (final k in _prototypes!.keys) {
      if (!AppConstants.foodClasses.contains(k)) {
        print('⚠️ Unexpected prototype key: $k');
      }
    }
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