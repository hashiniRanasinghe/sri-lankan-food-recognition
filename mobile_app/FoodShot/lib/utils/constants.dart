// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'FoodShot';
  static const String appSubtitle = 'Sri Lankan Food Recognition';
  static const String version = '1.0.0';
  
  // Design tokens
  static const double pagePadding = 16;
  static const double sectionSpacing = 16;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;

  // Model Info
  static const int imageSize = 224;
  static const int embeddingDim = 128;
  
  // Class Labels (8 classes from your dataset)
  static const List<String> foodClasses = [
    'Carrot (Raw)',
    'Carrot (White Curry)',
    'Green Beans (Raw)',
    'Green Beans (Tempered)',
    'Green Beans (White Curry)',
    'Pumpkin (Raw)',
    'Pumpkin (Red Curry)',
    'Pumpkin (White Curry)',
  ];
  
  // Colors (soft, minimal, AI-inspired)
  static const Color seedColor = Color(0xFF4F46E5); // soft indigo
  static const Color primaryColor = seedColor;
  static const Color accentColor = Color(0xFF14B8A6); // teal accent
  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE8EAF2);
  
  // ImageNet normalization values
  static const List<double> mean = [0.485, 0.456, 0.406];
  static const List<double> std = [0.229, 0.224, 0.225];
}
