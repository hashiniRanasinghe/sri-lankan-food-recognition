// lib/screens/developer_guide_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class DeveloperGuideScreen extends StatelessWidget {
  const DeveloperGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          
          _buildSection(
            icon: Icons.info_outline,
            title: 'About the Model',
            content: '''
This app uses FoodShot, a few-shot learning framework for food recognition.

Architecture: Prototypical Networks
- Custom CNN embedding network
- 128-dimensional embeddings
- Trained on ${AppConstants.foodClasses.length} Sri Lankan food classes
- Works with minimal training data (40 images/class)
''',
          ),
          
          _buildSection(
            icon: Icons.download,
            title: 'Model Files',
            content: '''
Available formats:
- PyTorch (.pth) - For Python/research
- TorchScript (.pt) - For production deployment  
- TFLite (.tflite) - For mobile apps
- ONNX (.onnx) - For cross-platform

Download from: github.com/yourusername/foodshot
''',
          ),
          
          _buildCodeSection(
            title: 'Python Usage',
            language: 'Python',
            code: '''
import torch
from foodshot import FoodShotClassifier

# Load model
model = FoodShotClassifier.load('model.pth')

# Predict
result = model.predict('food_image.jpg')
print(f"Prediction: {result['class']}")
print(f"Confidence: {result['confidence']:.2%}")
''',
          ),
          
          _buildCodeSection(
            title: 'Flutter/Dart Usage',
            language: 'Dart',
            code: '''
import 'package:tflite_flutter/tflite_flutter.dart';

// Load model
final interpreter = await Interpreter.fromAsset(
  'assets/model/food_model.tflite'
);

// Preprocess image (224x224)
var input = preprocessImage(image);

// Run inference
var output = List.filled(128, 0.0).reshape([1, 128]);
interpreter.run(input, output);

// Compare with prototypes for classification
var prediction = compareWithPrototypes(output);
''',
          ),
          
          const SizedBox(height: 24),
          
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Keep this intentionally minimal: one message + subtle accent.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                border: Border.all(color: AppConstants.borderColor),
              ),
              child: Icon(
                Icons.integration_instructions_rounded,
                size: 24,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Integrate FoodShot in Your Project',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Use our pre-trained model in your applications',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
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
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSection({
    required String title,
    required String language,
    required String code,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      child: Icon(Icons.code, color: AppConstants.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                  },
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.radiusLg),
                bottomRight: Radius.circular(AppConstants.radiusLg),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.greenAccent,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening GitHub repository...'),
                ),
              );
            },
            icon: const Icon(Icons.code),
            label: const Text('View on GitHub'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening documentation...'),
                ),
              );
            },
            icon: const Icon(Icons.book),
            label: const Text('Full Documentation'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
