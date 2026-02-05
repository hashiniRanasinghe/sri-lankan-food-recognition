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
  String? _prediction;
  double? _confidence;
  bool _isLoading = false;
  bool _modelLoaded = false;
  
  final ImagePicker _picker = ImagePicker();
  final ModelService _modelService = ModelService();

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);
    
    try {
      await _modelService.loadModel();
      setState(() {
        _modelLoaded = true;
        _isLoading = false;
      });
      _showMessage('Model loaded successfully!', isError: false);
    } catch (e) {
      setState(() {
        _modelLoaded = false;
        _isLoading = false;
      });
      _showMessage('Model not available yet. Using demo mode.', isError: false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _prediction = null;
          _confidence = null;
          _isLoading = true;
        });

        // Run inference (or demo mode if model not loaded)
        final result = await _modelService.recognizeFood(_image!);
        
        setState(() {
          _prediction = result['class'];
          _confidence = result['confidence'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage('Error: ${e.toString()}', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cs.error : cs.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetImage() {
    setState(() {
      _image = null;
      _prediction = null;
      _confidence = null;
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
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroHeader(cs),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildStatusIndicator(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildInstructions(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildImageDisplay(),
                const SizedBox(height: AppConstants.sectionSpacing),
                _buildActionButtons(),
                const SizedBox(height: AppConstants.sectionSpacing),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_prediction != null)
                  ResultCard(
                    prediction: _prediction!,
                    confidence: _confidence!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            child: Icon(Icons.auto_awesome_rounded, color: cs.primary),
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
                  'Pick an image and get a prediction in seconds.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final cs = Theme.of(context).colorScheme;
    final bg = _modelLoaded ? Colors.green : cs.tertiary;
    final fg = _modelLoaded ? Colors.green.shade900 : cs.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _modelLoaded ? Icons.check_circle_rounded : Icons.bolt_rounded,
            color: bg,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _modelLoaded ? 'Model Ready' : 'Demo Mode',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.restaurant_rounded, size: 40, color: AppConstants.primaryColor),
            const SizedBox(height: 12),
            const Text(
              'Recognize Sri Lankan Food',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or select from gallery',
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
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use Camera or Gallery',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
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
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
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
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
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