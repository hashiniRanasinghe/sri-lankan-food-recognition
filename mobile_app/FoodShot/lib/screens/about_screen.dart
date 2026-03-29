// lib/screens/about_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  static const _githubUrl = AppConstants.repoUrl;
  static const _hfUrl = AppConstants.huggingFaceUrl;
  static const _kaggleUrl = AppConstants.kaggleDatasetUrl;
  static const _pypiUrl = AppConstants.pypiPackageUrl;
  static const _testPypiUrl = AppConstants.testPypiPackageUrl;

  Future<void> _openUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) _showCopied(context, 'Could not open link.');
      }
    } catch (_) {
      if (context.mounted) _showCopied(context, 'Could not open link.');
    }
  }

  void _copyToClipboard(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    _showCopied(context, 'Link copied to clipboard');
  }

  void _showCopied(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          // ── App identity card ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 64,
                    width:  64,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusLg),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    child: Icon(Icons.auto_awesome_rounded,
                        size: 28, color: cs.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Version ${AppConstants.version}',
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${AppConstants.author}',
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── About ────────────────────────────────────────────────────────
          _buildInfoCard(
            icon: Icons.lightbulb_outline_rounded,
            title: 'About This App',
            content:
                'FoodShot uses a Prototypical Network — a few-shot metric-learning '
                'architecture — to recognise Sri Lankan vegetables across different '
                'cooking states, entirely on-device with no internet required.\n\n'
                'It demonstrates transformation-invariant food recognition: vegetables '
                'change dramatically in colour and texture after cooking with turmeric, '
                'coconut milk, and traditional Sri Lankan methods. The model handles '
                'this by learning a shared 128-dimensional embedding space where images '
                'of the same dish cluster together regardless of preparation.',
          ),

          // ── Model & Architecture ─────────────────────────────────────────
          _buildInfoCard(
            icon: Icons.psychology_rounded,
            title: 'Model Architecture',
            content:
                'Architecture: Prototypical Network\n'
                '• Backbone: MobileNetV2 (pre-trained on ImageNet)\n'
                '• Embedding head: 128-dimensional dense layer\n'
                '• Classification: cosine similarity to class prototypes\n'
                '• OOD: max cosine gate (with softmax bypass) + entropy gate\n'
                '• Uncertain predictions: top-3 + colour sanity hints (no server)\n'
                '• Validation accuracy: ~90.25%\n'
                '• Inference: fully on-device via TFLite (no server needed)',
          ),

          // ── Dataset ──────────────────────────────────────────────────────
          _buildInfoCard(
            icon: Icons.dataset_rounded,
            title: 'Dataset — 8 Classes',
            content:
                'Trained on ${AppConstants.foodClasses.length} vegetable × cooking-state '
                'combinations:\n\n'
                '${AppConstants.foodClasses.map((c) => '• ${AppConstants.foodClassNames[c] ?? c}').join('\n')}\n\n'
                'Dataset available on Kaggle (link below).',
          ),

          const SizedBox(height: 8),

          // ── Open Source card ─────────────────────────────────────────────
          _buildLinksCard(context),

          const SizedBox(height: 24),

          Center(
            child: Text(
              '© 2026 FoodShot Research Project',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Reusable info card ────────────────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                height: 36,
                width:  36,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Icon(icon, color: AppConstants.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(content,
                style: const TextStyle(fontSize: 14, height: 1.6)),
          ],
        ),
      ),
    );
  }

  // ── Links card ────────────────────────────────────────────────────────────

  Widget _buildLinksCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                height: 36,
                width:  36,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                  border: Border.all(color: AppConstants.borderColor),
                ),
                child: Icon(Icons.open_in_new_rounded,
                    color: AppConstants.primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Resources',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _linkRow(context, '🐙  GitHub — Source Code', _githubUrl),
            _linkRow(context, '🤗  Hugging Face — Model', _hfUrl),
            _linkRow(context, '📊  Kaggle — Dataset', _kaggleUrl),
            _linkRow(context, '📦  PyPI — Python Package', _pypiUrl),
            _linkRow(context, '🧪  Test PyPI — Package (staging)', _testPypiUrl),
            const SizedBox(height: 8),
            const Text(
              'License: MIT',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkRow(BuildContext context, String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openUrl(context, url),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyToClipboard(context, url),
            tooltip: 'Copy link',
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
