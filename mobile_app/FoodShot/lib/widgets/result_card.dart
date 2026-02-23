// lib/widgets/result_card.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ResultCard extends StatelessWidget {
  final String prediction;
  final double confidence;
  final double? processingTime;
  final Map<String, double>? allScores;
  final bool isRecognizedAsFood;
  /// Non-null when inference failed entirely (e.g. no internet + no TFLite)
  final String? errorMessage;
  /// 'tflite', 'huggingface_api', or 'error'
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                // Badge showing which backend answered
                if (source != null && source != 'error')
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: source == 'huggingface_api'
                          ? Colors.orange.withValues(alpha: 0.12)
                          : Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: source == 'huggingface_api'
                            ? Colors.orange.withValues(alpha: 0.4)
                            : Colors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      source == 'huggingface_api' ? '☁ Online' : '📱 On-device',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: source == 'huggingface_api'
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Main prediction or "not recognized" message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRecognizedAsFood
                    ? cs.primaryContainer.withValues(alpha: 0.3)
                    : cs.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: isRecognizedAsFood
                      ? cs.primary.withValues(alpha: 0.3)
                      : cs.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  if (isRecognizedAsFood) ...[
                    Text(
                      _formatFoodName(prediction),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCookingStyle(prediction),
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(confidence * 100).toStringAsFixed(1)}% confidence',
                      style: TextStyle(
                        fontSize: 15,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      source == 'error'
                          ? Icons.wifi_off_rounded
                          : Icons.no_food_rounded,
                      size: 48,
                      color: cs.error,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      source == 'error'
                          ? 'Could not get a prediction'
                          : 'Not a recognized food',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Show specific error message if inference failed
                    if (source == 'error' && errorMessage != null) ...[
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Text(
                        'This doesn\'t look like Sri Lankan food.\nPlease take a clear photo of:',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Carrot · Green Beans · Pumpkin\n(raw, white curry, red curry or tempered)',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            // Confidence indicator (only when recognized)
            if (isRecognizedAsFood) ...[
              const SizedBox(height: 16),
              _buildConfidenceBar(confidence, cs),
            ],
            
            // Processing time
            if (processingTime != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Processed in ${processingTime!.toStringAsFixed(2)}s',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            
            // Top predictions (only when recognized)
            if (isRecognizedAsFood && allScores != null && allScores!.length > 1) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Top Predictions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...allScores!.entries.take(3).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_formatFoodName(entry.key)} ${_formatCookingStyle(entry.key)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${(entry.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(double confidence, ColorScheme cs) {
    Color getConfidenceColor() {
      if (confidence >= 0.75) return Colors.green;
      if (confidence >= 0.5) return Colors.orange;
      return Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Confidence Level',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              confidence >= 0.75
                  ? 'High'
                  : confidence >= 0.5
                      ? 'Medium'
                      : 'Low',
              style: TextStyle(
                fontSize: 12,
                color: getConfidenceColor(),
                fontWeight: FontWeight.w600,
              ),
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
            valueColor: AlwaysStoppedAnimation<Color>(getConfidenceColor()),
          ),
        ),
      ],
    );
  }

  /// Converts "carrot_raw" → "Carrot" and "pumpkin_red_curry" → "Pumpkin"
  String _formatFoodName(String label) {
    final parts = label.split('_');
    if (parts.isEmpty) return label;
    return parts.first[0].toUpperCase() + parts.first.substring(1);
  }

  /// Converts "carrot_raw" → "RAW" and "pumpkin_red_curry" → "RED CURRY"
  String _formatCookingStyle(String label) {
    final parts = label.split('_');
    if (parts.length <= 1) return '';
    return parts.sublist(1).join(' ').toUpperCase();
  }
}