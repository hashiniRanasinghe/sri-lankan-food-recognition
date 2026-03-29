// lib/widgets/result_card.dart

import 'dart:math';

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ResultCard extends StatelessWidget {
  final String prediction;
  final double confidence;
  final double? processingTime;
  final Map<String, double>? allScores;
  final bool isRecognizedAsFood;
  /// Low confidence and/or high entropy — show top-k, not a single firm label.
  final bool isUncertain;
  /// From service: `carrot` | `green_veg` | `neutral` — avoids wrong same-family copy.
  final String colorHint;
  final String? errorMessage;
  /// 'tflite' or 'error'
  final String? source;

  const ResultCard({
    Key? key,
    required this.prediction,
    required this.confidence,
    this.processingTime,
    this.allScores,
    this.isRecognizedAsFood = true,
    this.isUncertain = false,
    this.colorHint = 'neutral',
    this.errorMessage,
    this.source,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: cs.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Prediction Results',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Backend badge
                if (source != null && source != 'error')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '📱 On-device',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Main result box ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !isRecognizedAsFood
                    ? (source == 'error'
                        ? cs.errorContainer.withValues(alpha: 0.2)
                        : cs.errorContainer.withValues(alpha: 0.3))
                    : isUncertain
                        ? Colors.amber.withValues(alpha: 0.12)
                        : cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: !isRecognizedAsFood
                      ? cs.error.withValues(alpha: 0.3)
                      : isUncertain
                          ? Colors.amber.withValues(alpha: 0.45)
                          : cs.primary.withValues(alpha: 0.3),
                ),
              ),
              child: !isRecognizedAsFood
                  ? _buildNotRecognizedContent(cs)
                  : isUncertain
                      ? _buildUncertainContent(cs)
                      : _buildRecognizedContent(cs),
            ),

            // ── Confidence bar (recognized only) ────────────────────────────
            if (isRecognizedAsFood) ...[
              const SizedBox(height: 16),
              _buildConfidenceBar(confidence, cs, isUncertain: isUncertain),
            ],

            // ── Processing time ──────────────────────────────────────────────
            if (processingTime != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 15,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Processed in ${processingTime!.toStringAsFixed(2)}s  ·  On-device',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],

            // ── Top predictions / full ranking (recognized only) ─────────────
            if (isRecognizedAsFood &&
                allScores != null &&
                allScores!.length > 1) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              if (!isUncertain && confidence < 0.35) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 15, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Low confidence — the model is uncertain. '
                          'Try a clearer, well-lit photo.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                isUncertain ? 'Remaining classes' : 'Runner-up scores',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ...allScores!.entries
                  .skip(isUncertain ? 3 : 1)
                  .take(isUncertain ? 8 : 4)
                  .map((entry) => _buildScoreRow(entry, cs)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Uncertain (in-distribution but low confidence / high entropy) ────────

  Widget _buildUncertainContent(ColorScheme cs) {
    final top3 = (allScores?.entries.toList() ?? [])
      ..sort((a, b) => b.value.compareTo(a.value));

    final bool sameFamily = top3.length >= 2 &&
        _ingredientRootKey(top3[0].key) == _ingredientRootKey(top3[1].key);
    final String topRoot = top3.isNotEmpty ? _ingredientRootKey(top3[0].key) : '';
    final bool mismatchOrangeVsBeans =
        colorHint == 'carrot' && topRoot == 'greenbeans';
    final bool mismatchGreenVsCarrot =
        colorHint == 'green_veg' && topRoot == 'carrot';
    final bool colorModelMismatch =
        mismatchOrangeVsBeans || mismatchGreenVsCarrot;
    final bool sameFamilyFriendly =
        sameFamily && !colorModelMismatch;
    final String? familyTitle = sameFamilyFriendly
        ? _ingredientTitle(_ingredientRootKey(top3[0].key))
        : null;

    return Column(
      children: [
        Icon(Icons.help_outline_rounded, size: 44, color: Colors.amber.shade800),
        const SizedBox(height: 10),
        Text(
          colorModelMismatch
              ? 'Visual vs model mismatch'
              : (sameFamilyFriendly && familyTitle != null)
                  ? '$familyTitle — preparation unclear'
                  : 'Unable to confidently identify the food',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          mismatchOrangeVsBeans
              ? 'The picture looks orange (carrot-like), but the model’s best '
                  'scores are green bean classes. That can be lighting, a mixed '
                  'dish, label noise in training, or similar textures in the '
                  'embedding space. Use the variants below as hints only — not a '
                  'final label.'
              : mismatchGreenVsCarrot
                  ? 'The crop looks strongly green, but the model’s top scores '
                      'are carrot classes. Check lighting, mixed ingredients, '
                      'or dataset labelling. Variants below are hints only.'
              : sameFamilyFriendly && familyTitle != null
                  ? 'The model agrees this is ${familyTitle.toLowerCase()}, but raw '
                      'vs cooked curry styles score almost the same — common when '
                      'lighting or sauce colour is ambiguous. Variants below are '
                      'not a final label.'
                  : 'The model is unsure (low confidence and/or probabilities spread '
                      'across classes). Below are the most likely matches — not a final label.',
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            sameFamilyFriendly
                ? 'Preparation variants (top 3)'
                : 'Top 3 possible matches',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          min(3, top3.length),
          (i) {
            final e = top3[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}.',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayClassName(e.key),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(e.value * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Recognized food content ──────────────────────────────────────────────

  Widget _buildRecognizedContent(ColorScheme cs) {
    return Column(
      children: [
        // Food name large
        Text(
          _displayClassName(prediction),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          '${(confidence * 100).toStringAsFixed(1)}% confidence',
          style: TextStyle(
            fontSize: 15,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ── Not recognised content ───────────────────────────────────────────────

  Widget _buildNotRecognizedContent(ColorScheme cs) {
    final isError = source == 'error';
    return Column(
      children: [
        Icon(
          isError ? Icons.wifi_off_rounded : Icons.no_food_rounded,
          size: 48,
          color: cs.error,
        ),
        const SizedBox(height: 10),
        Text(
          isError
              ? 'Could not get a prediction'
              : 'Not a recognised food',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cs.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (isError && errorMessage != null)
          Text(
            errorMessage!,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          )
        else ...[
          Text(
            'This image doesn\'t match any Sri Lankan food in the dataset.\n'
            'Please try a clear photo of one of the supported items:',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _supportedItemRow('🥕', 'Carrot',
                    'Raw · White Curry'),
                const SizedBox(height: 4),
                _supportedItemRow('🫘', 'Green Beans',
                    'Raw · Tempered · White Curry'),
                const SizedBox(height: 4),
                _supportedItemRow('🎃', 'Pumpkin',
                    'Raw · Red Curry · White Curry'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tips: good lighting, fill the frame, avoid blur.',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _supportedItemRow(String emoji, String name, String styles) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          name,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          '($styles)',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  // ── Score row ────────────────────────────────────────────────────────────

  Widget _buildScoreRow(
      MapEntry<String, double> entry, ColorScheme cs) {
    final pct = entry.value * 100;
    final isTop = entry.key == prediction;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          // Highlight top class
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTop
                  ? cs.primary
                  : cs.outlineVariant,
            ),
          ),
          Expanded(
            child: Text(
              _displayClassName(entry.key),
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isTop ? FontWeight.w600 : FontWeight.normal,
                color: isTop ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '${pct.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
              color: isTop ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Confidence bar ───────────────────────────────────────────────────────

  Widget _buildConfidenceBar(double conf, ColorScheme cs,
      {bool isUncertain = false}) {
    Color barColor() {
      if (isUncertain) return Colors.amber.shade700;
      if (conf >= 0.70) return Colors.green;
      if (conf >= 0.45) return Colors.orange;
      return Colors.red;
    }

    String label() {
      if (isUncertain) return 'Uncertain';
      if (conf >= 0.70) return 'High';
      if (conf >= 0.45) return 'Medium';
      return 'Low';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isUncertain ? 'Best candidate score' : 'Confidence level',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              label(),
              style: TextStyle(
                fontSize: 12,
                color: barColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: conf,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor()),
          ),
        ),
      ],
    );
  }

  // ── Label formatting helpers ─────────────────────────────────────────────

  /// First token of `snake_case` class id, e.g. `greenbeans_white_curry` → `greenbeans`.
  String _ingredientRootKey(String label) {
    final i = label.indexOf('_');
    return i < 0 ? label : label.substring(0, i);
  }

  /// Heading-style name; use `.toLowerCase()` in running text.
  String _ingredientTitle(String root) {
    switch (root) {
      case 'greenbeans':
        return 'Green beans';
      case 'carrot':
        return 'Carrot';
      case 'pumpkin':
        return 'Pumpkin';
      default:
        if (root.isEmpty) return 'This food';
        return root[0].toUpperCase() + root.substring(1);
    }
  }

  /// Human-readable label from [AppConstants.foodClassNames].
  String _displayClassName(String label) {
    return AppConstants.foodClassNames[label] ??
        label
            .replaceAll('_', ' ')
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
            .join(' ');
  }
}
