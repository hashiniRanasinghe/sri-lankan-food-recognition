// lib/utils/constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'FoodShot';
  static const String appSubtitle = 'Sri Lankan Food Recognition';
  static const String version = '1.0.0';
  static const String author = 'Hashini Ranasinghe';

  // API Configuration
  // ⚠️ CHANGE THIS to your deployed backend URL
  static const String apiUrl = 'http://10.0.2.2:5000'; // Android emulator
  // static const String apiUrl = 'http://localhost:5000'; // iOS simulator
  // static const String apiUrl = 'https://your-app.onrender.com'; // Production

  // Design tokens
  static const double pagePadding = 16;
  static const double sectionSpacing = 16;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;

  // Model Info
  static const int imageSize = 224;
  static const int embeddingDim = 128;

  // Class Labels (8 original classes)
  static const List<String> foodClasses = [
    'carrot_raw',
    'carrot_white_curry',
    'greenbeans_raw',
    'greenbeans_tempered',
    'greenbeans_white_curry',
    'pumpkin_raw',
    'pumpkin_red_curry',
    'pumpkin_white_curry',
  ];

  // Display names
  static const Map<String, String> foodClassNames = {
    'carrot_raw': 'Carrot (Raw)',
    'carrot_white_curry': 'Carrot White Curry',
    'greenbeans_raw': 'Green Beans (Raw)',
    'greenbeans_tempered': 'Green Beans Tempered',
    'greenbeans_white_curry': 'Green Beans White Curry',
    'pumpkin_raw': 'Pumpkin (Raw)',
    'pumpkin_red_curry': 'Pumpkin Red Curry',
    'pumpkin_white_curry': 'Pumpkin White Curry',
  };

  // Colors
  static const Color seedColor = Color(0xFF4F46E5);
  static const Color primaryColor = seedColor;
  static const Color accentColor = Color(0xFF14B8A6);
  static const Color backgroundColor = Color(0xFFF7F8FC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFE8EAF2);

  // ImageNet normalization
  static const List<double> mean = [0.485, 0.456, 0.406];
  static const List<double> std = [0.229, 0.224, 0.225];

  // Appendix A — repository, model, dataset, packages (keep in sync with report)
  static const String repoUrl =
      'https://github.com/hashiniRanasinghe/sri-lankan-food-recognition/tree/dev1';
  static const String huggingFaceUrl =
      'https://huggingface.co/ranasinghehashini/srilankan-food-recognition';
  static const String kaggleDatasetUrl =
      'https://www.kaggle.com/datasets/ranasinghehashini/sri-lankan-food-recognition-dataset?resource=download';
  static const String pypiPackageUrl =
      'https://pypi.org/project/srilankan-food-trainer/';
  static const String testPypiPackageUrl =
      'https://test.pypi.org/project/srilankan-food-trainer/';
}
