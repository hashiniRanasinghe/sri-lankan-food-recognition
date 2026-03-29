// lib/screens/developer_guide_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

class DeveloperGuideScreen extends StatelessWidget {
  const DeveloperGuideScreen({Key? key}) : super(key: key);

  static const githubUrl = AppConstants.repoUrl;
  static const hfUrl = AppConstants.huggingFaceUrl;
  static const kaggleUrl = AppConstants.kaggleDatasetUrl;
  static const pypiUrl = AppConstants.pypiPackageUrl;
  static const testPypiUrl = AppConstants.testPypiPackageUrl;

  static const colabUrl =
      'https://colab.research.google.com/drive/17QB6M18sc0AvvNTnqRGjOqVC3xQITuYi?usp=sharing';

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
            icon: Icons.psychology_rounded,
            title: 'About the Model',
            content:
                'This app uses a Prototypical Network — a few-shot metric-learning '
                'architecture — for on-device Sri Lankan food recognition.\n\n'
                'Architecture: Prototypical Network\n'
                '• Pre-trained MobileNetV2 backbone (ImageNet weights)\n'
                '• 128-dimensional embedding head\n'
                '• Trained on 8 Sri Lankan vegetable/cooking-state classes\n'
                '• Cosine-similarity classification against stored class prototypes\n'
                '• OOD + uncertainty handling (see OOD section below)\n'
                '• Achieves ~90% validation accuracy\n'
                '• Works with 20–50 images per class',
          ),

          _buildSection(
            icon: Icons.download_rounded,
            title: 'Model Files',
            content:
                'Available model formats:\n'
                '• TFLite (.tflite) — bundled in this app for on-device inference\n'
                '• PyTorch (.pth)   — for research / fine-tuning\n'
                '• ONNX (.onnx)     — for cross-platform deployment\n\n'
                'Download from:\n'
                '• GitHub: $githubUrl\n'
                '• Hugging Face: $hfUrl\n'
                '• Dataset on Kaggle: $kaggleUrl',
          ),

          _buildSection(
            icon: Icons.restaurant_menu_rounded,
            title: '8 Supported Food Classes',
            content:
                'The model recognises these Sri Lankan vegetable / cooking-state '
                'combinations:\n\n'
                '${AppConstants.foodClasses.map((c) => '• ${AppConstants.foodClassNames[c] ?? c}').join('\n')}\n\n'
                'You can add your own classes using the Python trainer package.',
          ),

          _buildSection(
            icon: Icons.tune_rounded,
            title: 'OOD & Uncertainty (current app build)',
            content:
                'Rejection uses two gates (see `food_recognition_service.dart`):\n\n'
                'Gate 1 — Max cosine similarity:\n'
                '  Reject only if max_sim < ~0.025 **and** top-1 softmax mass is '
                'still near chance (< ~0.129). If the model already favours one '
                'class above uniform 1/8, distance alone does not reject (avoids '
                'false OOD on phone crops / mean prototypes).\n\n'
                'Gate 2 — Entropy safety net:\n'
                '  Reject if Shannon entropy ≥ 2.00 **and** top-1 ≤ 13.5% '
                '(near-uniform guess).\n\n'
                'If accepted but confidence < 50% or entropy > 1.5, the UI shows '
                '**uncertain mode** (top-3, preparation-hint copy). Orange crops '
                'apply a small cosine debias toward `carrot_*` vs `greenbeans_*`. '
                'Hugging Face Inference API is not used — all inference is TFLite '
                'on-device.\n\n'
                'Test PyPI: $testPypiUrl',
          ),

          _buildCodeSection(
            title: 'Python — Add Your Own Class',
            language: 'Python',
            code: '''from srilankan_food_trainer import SriLankanFoodTrainer

# Initialise the Prototypical Network trainer
trainer = SriLankanFoodTrainer()

# Add a new class (20–50 images recommended)
trainer.add_class(
    class_name="your_food_name",
    images_path="/path/to/your/images"
)

# Fine-tune the embedding head
trainer.train(epochs=50)

# Predict on a new image
result = trainer.predict("food_image.jpg")
print(f"Class:      {result['class']}")
print(f"Confidence: {result['confidence']:.1%}")
print(f"Is food:    {result['is_food']}")

# Save updated model
trainer.save_model("best_model.pth")
''',
          ),

          _buildCodeSection(
            title: 'Google Colab — Quick Training',
            language: 'Python',
            code: '''# 1. Install the trainer package
!pip install srilankan-food-trainer

# 2. Upload your images as a ZIP archive
from google.colab import files
uploaded = files.upload()          # select your_food.zip

# 3. Train
from srilankan_food_trainer import SriLankanFoodTrainer

trainer = SriLankanFoodTrainer()
trainer.add_class_from_zip("your_food.zip")
trainer.train(epochs=50)

# 4. Export to TFLite for mobile
trainer.export_to_tflite("model.tflite")

# 5. Download
files.download("model.tflite")
''',
          ),

          _buildCodeSection(
            title: 'Flutter / Dart — Inference Snippet',
            language: 'Dart',
            code: '''import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:math';

// Load the TFLite model (4 CPU threads)
final interpreter = await Interpreter.fromAsset(
  'assets/model.tflite',
  options: InterpreterOptions()..threads = 4,
);

// Build NHWC input tensor [1][224][224][3] with ImageNet normalisation
// mean = [0.485, 0.456, 0.406], std = [0.229, 0.224, 0.225]
var input = buildNHWCTensor(preprocessedImage);   // your preprocess fn

// Run inference — output is [1][128] embedding
var output = List.generate(1, (_) => List.filled(128, 0.0));
interpreter.run(input, output);

// L2-normalise the embedding
final emb = l2Normalize(Float32List.fromList(output[0]));

// Cosine similarity against L2-normalised prototypes → softmax × 10
final sims = cosineSimilarities(emb, prototypes);
final probs = softmax(sims, temperature: 10.0);

// OOD check: max cosine similarity < 0.20 → not a recognised food
final maxSim = sims.values.reduce(max);
final isFood = maxSim >= 0.20;
''',
          ),

          _buildCodeSection(
            title: 'Model Conversion',
            language: 'Python',
            code: '''import torch
from srilankan_food_trainer import SriLankanFoodTrainer

# Load trained PyTorch model
trainer = SriLankanFoodTrainer()
trainer.load_model("best_model.pth")

# Export to TFLite for mobile (Flutter / Android / iOS)
trainer.export_to_tflite("model.tflite")

# Export to ONNX for cross-platform deployment
trainer.export_to_onnx("model.onnx")

# Export to TorchScript for production Python servers
scripted = torch.jit.script(trainer.model)
scripted.save("model.pt")
''',
          ),

          const SizedBox(height: 24),

          _buildActionButtons(context),

          const SizedBox(height: 16),

          _buildTipsCard(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

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
              'Prototypical Network · 128-dim embeddings · On-device TFLite',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                  child:
                      Icon(icon, color: AppConstants.primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 14, height: 1.6)),
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
                  child: Icon(Icons.code,
                      color: AppConstants.primaryColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        language,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => Clipboard.setData(ClipboardData(text: code)),
                  tooltip: 'Copy code',
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  fontSize: 12,
                  color: Colors.greenAccent,
                  height: 1.55,
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
        _linkButton(
          context: context,
          label: 'View Source on GitHub',
          icon: Icons.code,
          url: githubUrl,
          filled: true,
        ),
        const SizedBox(height: 10),
        _linkButton(
          context: context,
          label: 'Download Model — Hugging Face',
          icon: Icons.cloud_download_rounded,
          url: hfUrl,
        ),
        const SizedBox(height: 10),
        _linkButton(
          context: context,
          label: 'Dataset on Kaggle',
          icon: Icons.dataset_rounded,
          url: kaggleUrl,
        ),
        const SizedBox(height: 10),
        _linkButton(
          context: context,
          label: 'Python Package on PyPI',
          icon: Icons.code_rounded,
          url: pypiUrl,
        ),
        const SizedBox(height: 10),
        _linkButton(
          context: context,
          label: 'Try Training in Google Colab',
          icon: Icons.play_circle_outline_rounded,
          url: colabUrl,
        ),
      ],
    );
  }

  Widget _linkButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String url,
    bool filled = false,
  }) {
    final style = filled
        ? ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(14),
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          )
        : OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(14),
            minimumSize: const Size(double.infinity, 48),
          );

    return filled
        ? ElevatedButton.icon(
            onPressed: () => _launchUrl(context, url),
            icon: Icon(icon),
            label: Text(label),
            style: style,
          )
        : OutlinedButton.icon(
            onPressed: () => _launchUrl(context, url),
            icon: Icon(icon),
            label: Text(label),
            style: style,
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
                  child: const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Training Tips',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Use 20–50 high-quality images per class\n'
              '• Ensure good lighting and clear focus\n'
              '• Capture variety in angles, backgrounds, and portion sizes\n'
              '• Train for 50–100 epochs for best results\n'
              '• Target ≥ 90% validation accuracy before exporting\n'
              '• Use GPU in Colab for significantly faster training\n'
              '• Re-normalise class prototypes after adding new classes',
              style: TextStyle(fontSize: 14, height: 1.6),
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
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Could not open $urlString'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error opening link: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}
