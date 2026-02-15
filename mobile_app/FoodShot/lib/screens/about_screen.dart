// lib/screens/about_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // Opens in default browser
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void _copyToClipboard(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusLg,
                      ),
                      border: Border.all(color: AppConstants.borderColor),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 28,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${AppConstants.version}',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // lib/screens/about_screen.dart (CONTENT FIXES)
          _buildInfoCard(
            icon: Icons.lightbulb_outline,
            title: 'About This App',
            content: '''
FoodShot uses few-shot learning to recognize Sri Lankan vegetables across different cooking states with minimal training data.

This demonstrates Prototypical Networks applied to cultural food recognition where color, texture, and appearance change dramatically during cooking.
''',
          ),

          //           _buildInfoCard(
          //             icon: Icons.school,
          //             title: 'Research Project',
          //             content: '''
          // This is a final-year research project exploring transformation-invariant food recognition using metric learning.

          // The model recognizes vegetables even after dramatic visual changes from turmeric, coconut milk, and traditional Sri Lankan cooking methods.
          // ''',
          //           ),

          //           _buildInfoCard(
          //             icon: Icons.dataset,
          //             title: 'Dataset & Classes',
          //             content:
          //                 '''
          // Trained on ${AppConstants.foodClasses.length} vegetable-state combinations:

          // ${AppConstants.foodClasses.map((c) => '• $c').join('\n')}

          // Each class has 50-100 training images capturing authentic Sri Lankan preparations.
          // ''',
          //           ),
          _buildInfoCard(
            icon: Icons.dataset,
            title: 'Dataset',
            content:
                '''
Trained on ${AppConstants.foodClasses.length} classes of Sri Lankan food:
${AppConstants.foodClasses.map((c) => '• $c').join('\n')}
''',
          ),

          const SizedBox(height: 24),

          _buildOpenSourceCard(context),

          const SizedBox(height: 24),

          const Center(
            child: Text(
              '© 2026 FoodShot Research Project',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenSourceCard(BuildContext context) {
    const githubUrl =
        'https://github.com/hashiniRanasinghe/sri-lankan-food-recognition/tree/dev1';

    const hfUrl =
        'https://huggingface.co/ranasinghehashini/srilankan-food-recognition';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(color: AppConstants.borderColor),
                  ),
                  child: Icon(
                    Icons.code_off,
                    color: AppConstants.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Open Source',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This project is open source and available online.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),

            // GitHub Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openUrl(githubUrl),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        ' GitHub Repository',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(context, githubUrl),
                ),
              ],
            ),

            // const SizedBox(height: 8),

            // HuggingFace Row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openUrl(hfUrl),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        ' Hugging Face Model',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copyToClipboard(context, hfUrl),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Text('License: MIT', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

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
            Row(
              children: [
                Container(
                  height: 36,
                  width: 36,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }
}
