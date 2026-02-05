// lib/widgets/result_card.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ResultCard extends StatelessWidget {
  final String prediction;
  final double confidence;

  const ResultCard({
    Key? key,
    required this.prediction,
    required this.confidence,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: cs.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recognition Result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            // Prediction
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(color: AppConstants.borderColor),
              ),
              child: Column(
                children: [
                  const Text(
                    'Food Type:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    prediction,
                    style: TextStyle(
                      fontSize: 24,
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Confidence
            Column(
              children: [
                Text(
                  'Confidence',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Confidence bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  child: LinearProgressIndicator(
                    value: confidence,
                    minHeight: 10,
                    backgroundColor: AppConstants.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getConfidenceColor(confidence),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  '${(confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _getConfidenceColor(confidence),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Interpretation
            _buildInterpretation(confidence),
          ],
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildInterpretation(double confidence) {
    String message;
    IconData icon;
    Color color;

    if (confidence >= 0.8) {
      message = 'High confidence - Very likely correct';
      icon = Icons.thumb_up;
      color = Colors.green;
    } else if (confidence >= 0.6) {
      message = 'Medium confidence - Probably correct';
      icon = Icons.lightbulb_outline;
      color = Colors.orange;
    } else {
      message = 'Low confidence - May need verification';
      icon = Icons.warning_amber;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
