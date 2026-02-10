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

<table>
<tr>
<td><img src="docs/images/carrot_raw.jpg" width="200"/><br/><b>Carrot (Raw)</b><br/>Bright orange</td>
<td><img src="docs/images/carrot_curry.jpg" width="200"/><br/><b>Carrot (Red Curry)</b><br/>Yellow from turmeric</td>
<td><img src="docs/images/carrot_white.jpg" width="200"/><br/><b>Carrot (White Curry)</b><br/>Cream from coconut milk</td>
</tr>
</table>

Traditional food recognition systems fail because they rely on color, texture, and shape—all of which change dramatically during Sri Lankan cooking.

---

## ✨ Features

### 🎯 Core Capabilities
- **9 Vegetable-State Combinations**: Carrot (Raw/Red Curry/White Curry), Green Beans (Raw/Tempered/White Curry), Pumpkin (Raw/Red Curry/White Curry)
- **90.25% Validation Accuracy** on held-out test set
- **Transformation-Aware Learning**: Uses cooking method as contextual information
- **Few-Shot Learning**: Requires only 50-100 images per class for extension

### 📱 Mobile App
- **On-Device Inference**: Works offline, <2 second predictions
- **TFLite Optimization**: Model runs efficiently on mobile devices
- **Clean UI**: Camera/gallery support with confidence visualization
- **Cross-Platform**: iOS and Android support

### 🔧 Python Library
- **5-Line Extension API**: Add new classes without retraining original dataset
- **Transfer Learning**: Preserves knowledge of existing classes
- **PyPI Package**: `pip install srilankan-food-trainer`

---

## 🚀 Quick Start

### 1️⃣ Use Pre-Trained Model (Inference)

```python
# Install library
pip install srilankan-food-trainer

# Load model from HuggingFace
from srilankan_food_trainer import load_pretrained_model, predict_image

model, classes = load_pretrained_model()
result = predict_image(model, "path/to/food_image.jpg", classes)

print(f"Predicted: {result['class']} ({result['confidence']:.2%})")
```

### 2️⃣ Extend Model with New Class

```python
from srilankan_food_trainer import FoodModelExtender

# Create extender
extender = FoodModelExtender(verbose=True)

# Add new class (e.g., potato_tempered)
extender.add_class("potato_tempered", "potato_tempered.zip", auto_extract=True)

# Train (preserves original 8 classes + adds new one)
results = extender.train(epochs=50)

# Save extended model
extender.save("extended_model.pth")
```

### 3️⃣ Run Mobile App

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
| **Validation Accuracy** | 90.25% |
| **Test Accuracy** | 88.73% |
| **Inference Time (CPU)** | 1.8s |
| **Mobile Inference** | <2s |
| **Model Size (TFLite)** | 12 MB |

### Per-Class Performance

| Class | Precision | Recall | F1-Score |
|-------|-----------|--------|----------|
| carrot_raw | 0.95 | 0.92 | 0.93 |
| carrot_red_curry | 0.92 | 0.91 | 0.91 |
| carrot_white_curry | 0.88 | 0.90 | 0.89 |
| greenbeans_raw | 0.91 | 0.89 | 0.90 |
| greenbeans_tempered | 0.87 | 0.88 | 0.87 |
| greenbeans_white_curry | 0.89 | 0.91 | 0.90 |
| pumpkin_raw | 0.93 | 0.92 | 0.92 |
| pumpkin_red_curry | 0.86 | 0.87 | 0.86 |
| pumpkin_white_curry | 0.88 | 0.89 | 0.88 |

---

## 🏗️ Architecture

### Prototypical Network Design

```
Input Image (224×224)
    ↓
Embedding Network (Custom CNN)
├── Conv Block 1: 64 filters
├── Conv Block 2: 128 filters  
├── Conv Block 3: 256 filters
├── Conv Block 4: 512 filters
└── Global Average Pooling
    ↓
Embedding Vector (128-dim)
    ↓
Prototypical Classification
├── Compute distance to class prototypes
├── Apply transformation-aware weighting
└── Return nearest class + confidence
```

### Key Innovations

1. **Transformation-Invariant Embeddings**: Learned features remain consistent across cooking states
2. **Hierarchical Learning**: Cooking method context guides feature extraction
3. **Metric Learning**: Distance-based classification instead of softmax
4. **Few-Shot Capability**: Extends to new classes with minimal examples

---

## 📁 Repository Structure

```
sri-lankan-food-recognition/
├── model/                    # Model architecture & training
│   ├── architecture.py       # PrototypicalNetwork class
│   ├── train.py             # Training script
│   ├── evaluate.py          # Evaluation utilities
│   └── export_tflite.py     # Mobile model export
│
├── mobile_app/              # Flutter mobile application
│   ├── lib/                 # Dart source code
│   ├── assets/              # TFLite model files
│   └── README.md            # Mobile setup guide
│
├── srilankan-food-trainer/  # Python extension library
│   ├── src/                 # Library source code
│   ├── setup.py             # PyPI package config
│   └── README.md            # Library documentation
│
├── notebooks/               # Jupyter/Colab notebooks
│   ├── 01_Training.ipynb    # Full training pipeline
│   ├── 02_Evaluation.ipynb  # Results visualization
│   ├── 03_TFLite_Export.ipynb # Mobile export
│   └── 04_Extension_Demo.ipynb # Extension tutorial
│
├── results/                 # Training outputs
│   ├── metrics/             # JSON metrics
│   └── plots/               # Visualizations
│
├── docs/                    # Documentation
│   ├── SETUP.md             # Environment setup
│   ├── TRAINING.md          # Training guide
│   └── MOBILE_DEPLOYMENT.md # Mobile deployment
│
└── dataset/                 # Dataset info (not images)
    └── README.md            # Dataset description
```


## 📦 Dataset

### Dataset Structure
- **9 Classes**: 3 vegetables × 3 cooking states each
- **Training**: ~50-100 images per class
- **Sources**: Controlled captures + web scraping
- **Augmentation**: Rotation, flip, brightness, color jitter

### Classes Included
1. `carrot_raw` - Fresh carrot slices
2. `carrot_red_curry` - Carrot in turmeric curry
3. `carrot_white_curry` - Carrot in coconut milk curry
4. `greenbeans_raw` - Fresh green beans
5. `greenbeans_tempered` - Stir-fried green beans
6. `greenbeans_white_curry` - Green beans in coconut curry
7. `pumpkin_raw` - Fresh pumpkin cubes
8. `pumpkin_red_curry` - Pumpkin in turmeric curry
9. `pumpkin_white_curry` - Pumpkin in coconut curry


---


## 🔬 Usage Examples

### Training from Scratch

```python
from model.train import train_model
from model.architecture import PrototypicalNetwork

# Initialize model
model = PrototypicalNetwork(embedding_dim=128)

# Train
results = train_model(
    model=model,
    train_dir="dataset/train",
    val_dir="dataset/val",
    epochs=50,
    batch_size=32,
    learning_rate=0.001
)

# Save
torch.save(model.state_dict(), "my_model.pth")
```

### Evaluation

```python
from model.evaluate import evaluate_model

# Load model
model = load_model("best_model.pth")

# Evaluate
metrics = evaluate_model(
    model=model,
    test_dir="dataset/test",
    save_plots=True,
    output_dir="results/"
)

print(f"Test Accuracy: {metrics['accuracy']:.2%}")
```

### TFLite Export for Mobile

```python
from model.export_tflite import export_to_tflite

# Export
export_to_tflite(
    model_path="best_model.pth",
    output_dir="mobile_app/assets/",
    quantize=True  # Reduce model size
)

# Generates: model.tflite, prototypes.json, labels.txt
```

---

### Download APK
📥 [Latest Release (v1.0.0)](https://github.com/yourusername/sri-lankan-food-recognition/releases)

---

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- 🍅 Add more vegetables (tomato, cabbage, brinjal, etc.)
- 🍛 Add more cooking states (boiled, steamed, fried)
- 🌍 Extend to other South Asian cuisines



## 🔗 Links

- 🤗 [Pre-trained Model](https://huggingface.co/ranasinghehashini/srilankan-food-recognition)
- 📦 [Python Library](https://pypi.org/project/srilankan-food-trainer/)
- 📱 [Mobile App Releases](https://github.com/yourusername/sri-lankan-food-recognition/releases)
- 📊 [Dataset](https://drive.google.com/your-link-here)
- 📖 [Documentation](https://github.com/yourusername/sri-lankan-food-recognition/tree/main/docs)

---
