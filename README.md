# 🍛 Sri Lankan Food Recognition

A transformation-aware deep learning system for recognizing vegetable ingredients across cooking states in Sri Lankan cuisine.

---

## 📖 Overview

Sri Lankan cooking dramatically transforms vegetable appearance through turmeric, coconut milk, and spices. This project solves the challenge of recognizing vegetables after cooking transformations using:

- **Prototypical Networks** for few-shot learning
- **Transformation-invariant embeddings** that work across cooking states
- **Mobile deployment** with on-device TFLite inference
- **Extensible architecture** allowing users to add new classes with minimal data

### The Problem

| Raw | Red Curry | White Curry |
|-----|-----------|-------------|
| 🟠 **Carrot (Raw)** — Bright orange | 🟡 **Pumpkin (Red Curry)** — Yellow from turmeric | 🤍 **Carrot (White Curry)** — Cream from coconut milk |

Traditional food recognition systems fail because they rely on color, texture, and shape — all of which change dramatically during Sri Lankan cooking.

---

## ✨ Features

### 🎯 Core Capabilities
- **8 Vegetable-State Combinations**: Carrot (Raw, White Curry), Green Beans (Raw, Tempered, White Curry), Pumpkin (Raw, Red Curry, White Curry)
- **90.25% Best Validation Accuracy** / **84.91% Full Test Accuracy** / **87.75% Few-Shot Test Accuracy**
- **Transformation-Aware Learning**: Learns features that remain consistent across cooking transformations
- **Few-Shot Learning**: Requires only 30–50 images per class

### 📱 Mobile App
- **On-Device Inference**: Works fully offline, <100ms predictions
- **TFLite Optimisation**: Model (492.9 KB) runs efficiently on Android
- **Clean UI**: Camera/gallery support with confidence visualisation
- **Cross-Platform**: Flutter-based (Android and iOS)

### 🔧 Python Library
- **Simple Extension API**: Add new classes without retraining the original model
- **Transfer Learning**: Preserves knowledge of existing 8 classes
- **PyPI Package**: `pip install srilankan-food-trainer`

---

## 🚀 Quick Start

### 1️⃣ Extend Model with New Class

```python
from srilankan_food_trainer import FoodModelExtender

# Create extender
extender = FoodModelExtender(verbose=True)

# Add new class (ZIP filename = class name, e.g. potato_tempered.zip)
extender.add_class("potato_tempered", "potato_tempered.zip", auto_extract=True)

# Train (preserves original 8 classes + adds new one)
results = extender.train(epochs=50)

# Save extended model
extender.save("extended_model.pth")
```

### 2️⃣ Run Mobile App

```bash
cd mobile_app
flutter pub get
flutter run
```

---

## 📊 Model Performance

### Overall Metrics

| Metric | Value |
|--------|-------|
| **Best Validation Accuracy** | 90.25% (epoch 52) |
| **Few-Shot Test Accuracy** | 87.75% (200 episodes, 1,600 predictions) |
| **Full Test Accuracy** | 84.91% (45/53 images correct) |
| **Mean Per-Class Accuracy** | 84.15% |
| **Average Confidence** | 85.32% |
| **Mobile Inference Time** | <100ms |
| **TFLite Model Size** | 492.9 KB |
| **Training Duration** | ~5–7 hours (55 epochs, CPU) |

### Per-Class Performance (Full Test Set)

| Class | Precision | Recall | F1-Score | Support |
|-------|-----------|--------|----------|---------|
| carrot_raw | 0.750 | 1.000 | 0.857 | 6 |
| carrot_white_curry | 0.667 | 0.333 | 0.444 | 6 |
| greenbeans_raw | 0.875 | 1.000 | 0.933 | 7 |
| greenbeans_tempered | 1.000 | 0.667 | 0.800 | 6 |
| greenbeans_white_curry | 1.000 | 1.000 | 1.000 | 7 |
| pumpkin_raw | 1.000 | 1.000 | 1.000 | 6 |
| pumpkin_red_curry | 0.778 | 0.875 | 0.824 | 8 |
| pumpkin_white_curry | 0.750 | 0.857 | 0.800 | 7 |
| **Macro Avg** | **0.852** | **0.842** | **0.832** | **53** |

---

## 🏗️ Architecture

### Prototypical Network Design

```
Input Image (224×224)
    ↓
Embedding Network (Custom CNN)
├── Conv Block 1: 32 filters, BN + ReLU + MaxPool
├── Conv Block 2: 64 filters, BN + ReLU + MaxPool
├── Conv Block 3: 128 filters, BN + ReLU + MaxPool
├── Conv Block 4: 256 filters, BN + ReLU + MaxPool
└── Global Average Pooling
    ↓
FC Layer 1: 256 units, ReLU, Dropout 0.3
    ↓
FC Layer 2: 128-dim Embedding Vector
    ↓
Prototypical Classification
├── Compute Euclidean distance to class prototypes
└── Return nearest class + confidence score
```

### Training Configuration
- **Episodes per epoch**: 100
- **Few-shot setup**: 4-way 2-shot
- **Total epochs trained**: 55 (best at epoch 52)
- **Optimiser**: Adam (lr=0.0001, StepLR ×0.5 at epoch 50)
- **Regularisation**: Dropout 0.3, Weight decay 0.0001

---

## 📁 Repository Structure

```
sri-lankan-food-recognition/
│
├── notebooks/                    # Colab training notebooks
│   ├── V1_SriLankanFoodRecognition.ipynb     # Full training pipeline
│   ├── Comprehensive_Baseline_Comparison.ipynb  # Baseline evaluation
│   ├── V1_Test_ranasinghehashini.ipynb        # Model export & TFLite
│   ├── V1_HuggingFace.ipynb                  # HuggingFace upload
│   └── Sri_Lankan_Food_Trainer_Tutorial_Enhanced.ipynb  # Extension tutorial
│
├── mobile_app/                   # Flutter mobile application
│   ├── lib/                      # Dart source code
│   └── assets/                   # TFLite model files
│       ├── model.tflite          # (492.9 KB)
│       ├── prototypes.json       # (25.9 KB, 8 class prototypes)
│       └── labels.txt            # (8 class labels)
│
├── srilankan-food-trainer/       # Python extension library (PyPI)
│   └── Sri_Lankan_Food_Trainer_Tutorial_Enhanced.ipynb
│
└── dataset/                      # Dataset info
    └── README.md
```

---

## 📦 Dataset

### Summary
- **8 Classes** across 3 vegetables and authentic cooking states
- **331 total images** (230 train / 48 val / 53 test)
- **~39–48 images per class**
- **Sources**: 40% controlled captures + 60% web scraping

> ⚠️ Note: Not every vegetable appears in all cooking states. This reflects authentic Sri Lankan culinary practice — for example, carrot appears in raw and white curry but not red curry in this dataset.

### Classes

| # | Class | Description |
|---|-------|-------------|
| 1 | `carrot_raw` | Fresh carrot — bright orange |
| 2 | `carrot_white_curry` | Carrot in coconut milk curry — cream coloured |
| 3 | `greenbeans_raw` | Fresh green beans — vibrant green |
| 4 | `greenbeans_tempered` | Stir-fried green beans — browned surfaces |
| 5 | `greenbeans_white_curry` | Green beans in coconut curry |
| 6 | `pumpkin_raw` | Fresh pumpkin — bright orange |
| 7 | `pumpkin_red_curry` | Pumpkin in turmeric curry — yellow-orange |
| 8 | `pumpkin_white_curry` | Pumpkin in coconut curry — cream coloured |

---

## 🔗 Links

- 🤗 [Pre-trained Model on Hugging Face](https://huggingface.co/ranasinghehashini/srilankan-food-recognition)
- 📦 [Python Library on PyPI](https://pypi.org/project/srilankan-food-trainer/)
- 📊 [Dataset on Kaggle](https://www.kaggle.com/datasets/ranasinghehashini/sri-lankan-food-recognition-dataset/data)

---

## 🤝 Contributing

Contributions are welcome! Planned future additions:
- 🍆 More vegetables (eggplant/brinjal, bitter gourd, drumstick, okra)
- 🍛 More cooking states (mallum, boiled, steamed)
- 🌍 Extension to other South Asian cuisines

---

<p align="center">
🍛 Preserving Sri Lankan culinary heritage through AI 🇱🇰
</p>