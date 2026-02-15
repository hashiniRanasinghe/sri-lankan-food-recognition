// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/constants.dart';
import '../services/model_service.dart';
import '../widgets/result_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  Map<String, dynamic>? _result;
  bool _isProcessing = false;
  bool _modelLoaded = false;

  final ImagePicker _picker = ImagePicker();
  final ModelService _modelService = ModelService();

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    final success = await _modelService.loadModel();
    if (mounted) {
      setState(() {
        _modelLoaded = success;
      });

      if (success) {
        _showMessage('Model loaded successfully!', isError: false);
      } else {
        _showMessage('Running in demo mode', isError: false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024, // Reduced from 800 for better quality
        maxHeight: 1024,
        imageQuality: 90, // Increased quality
      );

      if (pickedFile == null) return;

      // Show loading immediately
      setState(() {
        _image = File(pickedFile.path);
        _result = null;
        _isProcessing = true;
      });

      // Run inference
      final result = await _modelService.recognizeFood(_image!);

      if (mounted) {
        setState(() {
          _result = result;
          _isProcessing = false;
        });

        // Show demo mode warning if applicable
        if (result['is_demo'] == true) {
          _showMessage('Demo mode - using sample prediction', isError: false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _showMessage('Error: ${e.toString()}', isError: true);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        duration: Duration(seconds: isError ? 3 : 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetImage() {
    setState(() {
      _image = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => Navigator.pushNamed(context, '/developer'),
            tooltip: 'Developer Guide',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, '/about'),
            tooltip: 'About',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroHeader(cs),
              const SizedBox(height: AppConstants.sectionSpacing),
              // _buildStatusIndicator(),
              // const SizedBox(height: AppConstants.sectionSpacing),
              _buildInstructions(),
              const SizedBox(height: AppConstants.sectionSpacing),
              _buildImageDisplay(),
              const SizedBox(height: AppConstants.sectionSpacing),
              _buildActionButtons(),
              const SizedBox(height: AppConstants.sectionSpacing),

              // Results section
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Analyzing image...'),
                      ],
                    ),
                  ),
                )
              else if (_result != null)
                ResultCard(
                  prediction: _result!['class'] as String,
                  confidence: _result!['confidence'] as double,
                  processingTime: _result!['processing_time'] as double,
                  allScores: _result!['all_scores'] as Map<String, double>?,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (keep existing widget methods but add null safety)

  Widget _buildHeroHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.10),
            AppConstants.accentColor.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: cs.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appSubtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Snap a photo and get instant predictions',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildStatusIndicator() {
  //   final cs = Theme.of(context).colorScheme;
  //   final isReady = _modelLoaded && !_isProcessing;
  //   final bg = isReady ? Colors.green : cs.tertiary;
  //   final fg = isReady ? Colors.green.shade900 : cs.onSurface;

  //   // return Center(
  //   //   child: Container(
  //   //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //   //     decoration: BoxDecoration(
  //   //       color: bg.withValues(alpha: 0.10),
  //   //       borderRadius: BorderRadius.circular(999),
  //   //       border: Border.all(color: bg.withValues(alpha: 0.25)),
  //   //     ),
  //   //     child: Row(
  //   //       mainAxisSize: MainAxisSize.min,
  //   //       children: [
  //   //         Icon(
  //   //           isReady
  //   //               ? Icons.check_circle_rounded
  //   //               : Icons.hourglass_empty_rounded,
  //   //           color: bg,
  //   //           size: 16,
  //   //         ),
  //   //         const SizedBox(width: 8),
  //   //         Text(
  //   //           isReady
  //   //               ? 'Model Ready'
  //   //               : (_isProcessing ? 'Processing...' : 'Demo Mode'),
  //   //           style: TextStyle(
  //   //             color: fg,
  //   //             fontWeight: FontWeight.w700,
  //   //             fontSize: 13,
  //   //           ),
  //   //         ),
  //   //       ],
  //   //     ),
  //   //   ),
  //   // );
  // }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_rounded,
              size: 40,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'Recognize Sri Lankan Food',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or choose from your gallery',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: _image == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 80,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                ),
                const SizedBox(height: 16),
                Text(
                  'No image selected',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use Camera or Gallery below',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            )
          : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                  child: Image.file(
                    _image!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _resetImage,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                    ),
                    tooltip: 'Clear image',
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _modelService.dispose();
    super.dispose();
  }
}
