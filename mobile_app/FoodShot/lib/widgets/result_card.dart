// lib/widgets/result_card.dart
//
// Displays inference results following the three-tier confidence system
// defined in the report (Table 5, Section 5.2.5):
//
//   >= 75%  High     Green   Strong match; reliable for practical use
//   50-74%  Medium   Orange  Moderate confidence; consider top-3 alternatives
//   <  50%  Low      Red     Weak match; image may be ambiguous or outside
//                            trained classes
//
// "Not recognised" is shown only when the OOD distance gate rejects the image
// (black/corrupted frames). For all other inputs, the best prediction is always
// shown with the appropriate confidence tier.

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ResultCard extends StatelessWidget {
  final String prediction;
  final double confidence;
  final double? processingTime;
  final Map<String, double>? allScores;
  final bool isRecognizedAsFood;
  final String? errorMessage;
  final String? source;

  const ResultCard({
    Key? key,
    required this.prediction,
    required this.confidence,
    this.processingTime,
    this.allScores,
    this.isRecognizedAsFood = true,
    this.errorMessage,
    this.source,
  }) : super(key: key);

  // ── Confidence tier helpers (report Table 5) ─────────────────────────────

  bool get _isHigh   => confidence >= 0.75;
  bool get _isMedium => confidence >= 0.50 && confidence < 0.75;
  // ignore: unused_element
  bool get _isLow    => confidence < 0.50;

  Color _confidenceColor() {
    if (_isHigh)   return Colors.green.shade700;
    if (_isMedium) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _confidenceLabel() {
    if (_isHigh)   return 'High';
    if (_isMedium) return 'Medium';
    return 'Low';
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ─────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(Icons.auto_awesome_rounded,
                      color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Prediction Results',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // On-device inference badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4)),
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

            // ── Main result box ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: !isRecognizedAsFood
                    ? cs.errorContainer.withValues(alpha: 0.3)
                    : cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: !isRecognizedAsFood
                      ? cs.error.withValues(alpha: 0.3)
                      : cs.primary.withValues(alpha: 0.3),
                ),
              ),
              child: !isRecognizedAsFood
                  ? _buildNotRecognisedContent(cs)
                  : _buildPredictionContent(cs),
            ),

            // ── Confidence bar (recognised only, report Table 5) ────────────
            if (isRecognizedAsFood) ...[
              const SizedBox(height: 16),
              _buildConfidenceBar(cs),
            ],

            // ── Processing time ─────────────────────────────────────────────
            if (processingTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 15, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Processed in ${processingTime!.toStringAsFixed(2)}s',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],

            // ── Top Predictions ─────────────────────────────────────────────
            // Always shown when recognised so the user can compare
            // alternative preparations (most useful for Low and Medium tiers).
            if (isRecognizedAsFood &&
                allScores != null &&
                allScores!.length > 1) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Low-confidence advisory (report Table 5)
              if (confidence < 0.50) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 15, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Low confidence — the image may be ambiguous, '
                          'poorly lit, or outside the trained classes. '
                          'Review the alternatives below.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade900,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const Text(
                'Top Predictions',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),

              // Show all 3 predictions
              ...allScores!.entries.take(3).map(
                    (entry) => _buildScoreRow(entry, cs),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Recognised prediction content ────────────────────────────────────────

  Widget _buildPredictionContent(ColorScheme cs) {
    return Column(
      children: [
        // Food name (large, primary colour)
        Text(
          _foodName(prediction),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
          textAlign: TextAlign.center,
        ),
        // Cooking style (e.g. "WHITE CURRY")
        if (_cookingStyle(prediction).isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _cookingStyle(prediction),
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${(confidence * 100).toStringAsFixed(1)}% confidence',
          style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }

  // ── Not-recognised content ────────────────────────────────────────────────

  Widget _buildNotRecognisedContent(ColorScheme cs) {
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
            style: TextStyle(
                fontSize: 13, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          )
        else ...[
          Text(
            'This image does not match any Sri Lankan vegetable '
            'in the dataset.\nPlease try a clear photo of:',
            style: TextStyle(
                fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.07),
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                  color: cs.primary.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _classRow('🥕', 'Carrot',
                    'Raw · White Curry'),
                const SizedBox(height: 6),
                _classRow('🫘', 'Green Beans',
                    'Raw · Tempered · White Curry'),
                const SizedBox(height: 6),
                _classRow('🎃', 'Pumpkin',
                    'Raw · Red Curry · White Curry'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tips: good lighting · fill the frame · avoid blur',
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

  Widget _classRow(String emoji, String name, String styles) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(name,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Flexible(
          child: Text('($styles)',
              style: const TextStyle(
                  fontSize: 12, color: Colors.black54)),
        ),
      ],
    );
  }

  // ── Confidence bar (report Table 5) ──────────────────────────────────────

  Widget _buildConfidenceBar(ColorScheme cs) {
    final color = _confidenceColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence Level',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              _confidenceLabel(),
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ── Score row ─────────────────────────────────────────────────────────────

  Widget _buildScoreRow(MapEntry<String, double> entry, ColorScheme cs) {
    final isTop = entry.key == prediction;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTop ? cs.primary : cs.outlineVariant,
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
            '${(entry.value * 100).toStringAsFixed(1)}%',
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

  // ── Label helpers ─────────────────────────────────────────────────────────

  /// "carrot_white_curry" → "Carrot"
  String _foodName(String label) {
    final parts = label.split('_');
    if (parts.isEmpty) return label;
    final root = parts.first;
    if (root == 'greenbeans') return 'Green Beans';
    return '${root[0].toUpperCase()}${root.substring(1)}';
  }

  /// "carrot_white_curry" → "WHITE CURRY"
  String _cookingStyle(String label) {
    final parts = label.split('_');
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ').toUpperCase();
  }

  /// Full human-readable name from AppConstants or auto-formatted fallback.
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