// lib/screens/about_screen.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
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
                      borderRadius: BorderRadius.circular(AppConstants.radiusLg),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoCard(
            icon: Icons.lightbulb_outline,
            title: 'About This App',
            content: '''
FoodShot is a few-shot learning framework that recognizes Sri Lankan food from images with minimal training data.

This app demonstrates the practical application of Prototypical Networks for cultural food recognition.
''',
          ),
          
          _buildInfoCard(
            icon: Icons.school,
            title: 'Research',
            content: '''
This is a final year research project exploring few-shot learning for low-resource food recognition.

The goal is to enable anyone to create custom food classifiers with just 40 images per class.
''',
          ),
          
          _buildInfoCard(
            icon: Icons.dataset,
            title: 'Dataset',
            content: '''
Trained on ${AppConstants.foodClasses.length} classes of Sri Lankan food:
${AppConstants.foodClasses.map((c) => '• $c').join('\n')}
''',
          ),
          
          _buildInfoCard(
            icon: Icons.code_off,
            title: 'Open Source',
            content: '''
This project is open source and available on GitHub. Feel free to use it in your own projects!

License: MIT
''',
          ),
          
          const SizedBox(height: 24),
          
          const Center(
            child: Text(
              '© 2026 FoodShot Research Project',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
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
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
