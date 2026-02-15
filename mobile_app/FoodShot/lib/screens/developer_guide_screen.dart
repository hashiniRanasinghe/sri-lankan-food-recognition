// lib/screens/developer_guide_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class DeveloperGuideScreen extends StatelessWidget {
  const DeveloperGuideScreen({Key? key}) : super(key: key);

  static const githubUrl =
      'https://github.com/hashiniRanasinghe/sri-lankan-food-recognition/tree/dev1';

  static const hfUrl =
      'https://huggingface.co/ranasinghehashini/srilankan-food-recognition';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Developer Guide')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.pagePadding),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          _buildSection(
            icon: Icons.info_outline,
            title: 'About the Model',
            content: '''
This app uses the Sri Lankan Food Recognition model with transfer learning.

Architecture: Transfer Learning (Pre-trained CNN)
- Deep learning with fine-tuning
- Trained on 8 original Sri Lankan food classes
- Extendable with your own classes
- Works with minimal training data (20-50 images/class)
- Achieves 85-90%+ accuracy
''',
          ),

          _buildSection(
            icon: Icons.download,
            title: 'Model Files',
            content:
                '''
Available formats:
- PyTorch (.pth) - For Python/research
- TorchScript (.pt) - For production deployment  
- TFLite (.tflite) - For mobile apps
- ONNX (.onnx) - For cross-platform

Download from:
- GitHub: $githubUrl
- Hugging Face: $hfUrl
''',
          ),

          _buildSection(
            icon: Icons.restaurant_menu,
            title: 'Original 8 Food Classes',
            content:
                '''
The base model recognizes these Sri Lankan dishes:
${AppConstants.foodClasses.map((c) => '• $c').join('\n')}

You can add your own classes using the trainer!
''',
          ),

          _buildCodeSection(
            title: 'Python Usage - Add Your Class',
            language: 'Python',
            code: '''
from srilankan_food_trainer import SriLankanFoodTrainer

# Initialize trainer
trainer = SriLankanFoodTrainer()

# Add your own class
trainer.add_class(
    class_name="your_food_name",
    images_path="/path/to/images"  # 20-50 images
)

# Train the model
trainer.train(epochs=50)

# Predict
result = trainer.predict("food_image.jpg")
print(f"Class: {result['class']}")
print(f"Confidence: {result['confidence']:.1%}")

# Save model
trainer.save_model("best_model.pth")
''',
          ),

          _buildCodeSection(
            title: 'Google Colab Training',
            language: 'Python',
            code: '''
# 1. Install the library
!pip install srilankan-food-trainer

# 2. Upload your images as ZIP
from google.colab import files
uploaded = files.upload()

# 3. Train
from srilankan_food_trainer import SriLankanFoodTrainer

trainer = SriLankanFoodTrainer()
trainer.add_class_from_zip("your_food.zip")
trainer.train(epochs=50)

# 4. Download model
trainer.save_model("best_model.pth")
files.download("best_model.pth")
''',
          ),

          _buildCodeSection(
            title: 'Flutter/Dart Usage',
            language: 'Dart',
            code: '''
import 'package:tflite_flutter/tflite_flutter.dart';

// Load model
final interpreter = await Interpreter.fromAsset(
  'assets/model.tflite',
  options: InterpreterOptions()..threads = 4
);

// Preprocess image to 224x224 normalized
var input = preprocessImage(image);

// Run inference
var output = List.filled(numClasses, 0.0).reshape([1, numClasses]);
interpreter.run(input, output);

// Get prediction
var probabilities = output[0] as List<double>;
var maxIndex = probabilities.indexOf(probabilities.reduce(max));
var confidence = probabilities[maxIndex];

print('Predicted: \${classes[maxIndex]}');
print('Confidence: \${(confidence * 100).toStringAsFixed(1)}%');
''',
          ),

          _buildCodeSection(
            title: 'Model Conversion',
            language: 'Python',
            code: '''
import torch
from srilankan_food_trainer import SriLankanFoodTrainer

# Load PyTorch model
trainer = SriLankanFoodTrainer()
trainer.load_model("best_model.pth")

# Convert to TFLite for mobile
trainer.export_to_tflite("model.tflite")

# Convert to ONNX for cross-platform
trainer.export_to_onnx("model.onnx")

# Convert to TorchScript for production
model_scripted = torch.jit.script(trainer.model)
model_scripted.save("model.pt")
''',
          ),

          const SizedBox(height: 24),

          _buildActionButtons(context),

          const SizedBox(height: 16),

          _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              'Integrate Sri Lankan Food Recognition',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Use our pre-trained model in your applications',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
            Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
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
                    Icons.code,
                    color: AppConstants.primaryColor,
                    size: 18,
                  ),
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
            onPressed: () => _launchUrl(context, githubUrl),
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
            onPressed: () => _launchUrl(context, hfUrl),
            icon: const Icon(Icons.cloud_download),
            label: const Text('Hugging Face Models'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _launchUrl(
              context,
              'https://colab.research.google.com/drive/17QB6M18sc0AvvNTnqRGjOqVC3xQITuYi?usp=sharing',
            ),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Try in Google Colab'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard() {
    return Card(
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
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Training Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Use 20-50 high-quality images per class\n'
              '• Ensure good lighting and clear focus\n'
              '• Include variety in angles and backgrounds\n'
              '• Train for 50-100 epochs for best results\n'
              '• Aim for 85-90%+ validation accuracy\n'
              '• Use GPU in Colab for faster training',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $urlString'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
