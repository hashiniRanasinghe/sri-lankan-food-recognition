// lib/widgets/result_card.dart (NEW - COMPLETE IMPLEMENTATION)

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ResultCard extends StatelessWidget {
  final String prediction;
  final double confidence;
  final double? processingTime;
  final Map<String, double>? allScores;

  const ResultCard({
    Key? key,
    required this.prediction,
    required this.confidence,
    this.processingTime,
    this.allScores,
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
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Main prediction
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    prediction,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(confidence * 100).toStringAsFixed(1)}% confidence',
                    style: TextStyle(
                      fontSize: 16,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Confidence indicator
            const SizedBox(height: 16),
            _buildConfidenceBar(confidence, cs),
            
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
            
            // Top predictions
            if (allScores != null && allScores!.length > 1) ...[
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
                          entry.key,
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
}