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
  File?                  _image;
  Map<String, dynamic>?  _result;
  bool                   _isProcessing = false;
  bool                   _modelLoaded  = false;
  String?                _modelError;

  final ImagePicker  _picker       = ImagePicker();
  final ModelService _modelService = ModelService();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  @override
  void dispose() {
    _modelService.dispose();
    super.dispose();
  }

  // ── Model init ─────────────────────────────────────────────────────────────

  Future<void> _initializeModel() async {
    final success = await _modelService.loadModel();
    if (!mounted) return;
    setState(() {
      _modelLoaded = success;
      _modelError  = success ? null : _modelService.loadError;
    });

    if (!success) {
      _showSnack(
        'Model failed to load — check that assets/model.tflite is in pubspec.yaml',
        isError: true,
        duration: const Duration(seconds: 6),
      );
    }
  }

  // ── Image picking & inference ──────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source:       source,
        maxWidth:     1024,
        maxHeight:    1024,
        imageQuality: 90,
      );
      if (picked == null) return;

      setState(() {
        _image        = File(picked.path);
        _result       = null;
        _isProcessing = true;
      });

      final result = await _modelService.recognizeFood(_image!);

      if (!mounted) return;
      setState(() {
        _result       = result;
        _isProcessing = false;
      });

      // Surface inference errors as a snackbar too
      final err = result['error'] as String?;
      if (err != null && err.isNotEmpty) {
        _showSnack(err, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSnack('Unexpected error: $e', isError: true);
    }
  }

  void _resetImage() => setState(() { _image = null; _result = null; });

  // ── Snackbar ───────────────────────────────────────────────────────────────

  void _showSnack(String message,
      {required bool isError, Duration? duration}) {
    if (!mounted) return;
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(message),
      backgroundColor: isError ? cs.error : cs.primary,
      duration:        duration ?? Duration(seconds: isError ? 4 : 2),
      behavior:        SnackBarBehavior.floating,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon:    const Icon(Icons.code),
            onPressed: () => Navigator.pushNamed(context, '/developer'),
            tooltip: 'Developer Guide',
          ),
          IconButton(
            icon:    const Icon(Icons.info_outline),
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
              _buildModelStatusBadge(cs),
              const SizedBox(height: AppConstants.sectionSpacing),
              _buildImageDisplay(cs),
              const SizedBox(height: AppConstants.sectionSpacing),
              _buildActionButtons(),
              const SizedBox(height: AppConstants.sectionSpacing),

              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analysing image…'),
                    ]),
                  ),
                )
              else if (_result != null)
                ResultCard(
                  prediction:          _result!['class']                as String,
                  confidence:          _result!['confidence']           as double,
                  processingTime:      _result!['processing_time']      as double?,
                  allScores:           _result!['all_scores']           as Map<String, double>?,
                  isRecognizedAsFood:  _result!['is_recognized_as_food'] as bool? ?? false,
                  errorMessage:        _result!['error']                as String?,
                  source:              _result!['source']               as String?,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeroHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.10),
            AppConstants.accentColor.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Row(children: [
        Container(
          height: 44,
          width:  44,
          decoration: BoxDecoration(
            color:        cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Icon(Icons.auto_awesome_rounded, color: cs.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appSubtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:       cs.onSurface,
                  fontWeight:  FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Snap a photo and get instant predictions',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  /// Small pill that shows whether TFLite loaded successfully.
  /// Makes it easy to spot asset/model problems during development.
  Widget _buildModelStatusBadge(ColorScheme cs) {
    final ready  = _modelLoaded && !_isProcessing;
    final color  = ready ? Colors.green : Colors.orange;
    final icon   = ready
        ? Icons.check_circle_rounded
        : (_modelError != null ? Icons.error_rounded : Icons.hourglass_top_rounded);
    final label  = ready
        ? '📱 On-device model ready'
        : (_modelError != null ? '⚠ Model not loaded' : 'Loading model…');

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border:       Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color:       color.shade800,
              fontSize:    12,
              fontWeight:  FontWeight.w600,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildImageDisplay(ColorScheme cs) {
    return Container(
      height: 300,
      width:  double.infinity,
      decoration: BoxDecoration(
        color:        cs.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        border:       Border.all(color: AppConstants.borderColor),
      ),
      child: _image == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_outlined,
                    size: 80,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55)),
                const SizedBox(height: 16),
                Text('No image selected',
                    style: TextStyle(
                      color:      cs.onSurfaceVariant,
                      fontSize:   16,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 8),
                Text('Use Camera or Gallery below',
                    style: Theme.of(context)
                        .textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ],
            )
          : Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                child: Image.file(_image!,
                    fit:    BoxFit.cover,
                    width:  double.infinity,
                    height: double.infinity),
              ),
              Positioned(
                top: 8, right: 8,
                child: IconButton(
                  icon:    const Icon(Icons.close),
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
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
            ]),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _pickImage(ImageSource.camera),
              icon:  const Icon(Icons.camera_alt_rounded),
              label: const Text('Camera'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _pickImage(ImageSource.gallery),
              icon:  const Icon(Icons.photo_library_rounded),
              label: const Text('Gallery'),
            ),
          ),
        ]),
      ),
    );
  }
}
