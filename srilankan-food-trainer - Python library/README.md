# 🍛 Sri Lankan Food Trainer

[![PyPI version](https://badge.fury.io/py/srilankan-food-trainer.svg)](https://pypi.org/project/srilankan-food-trainer/)
[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![PyTorch](https://img.shields.io/badge/PyTorch-2.0+-red.svg)](https://pytorch.org/)

Easy-to-use Python library for extending the **Sri Lankan Food Recognition** model with your own vegetable classes — no deep learning expertise required.

Built on a custom Prototypical Network trained on 8 Sri Lankan vegetable–cooking state combinations. Add a new class with as few as **20–30 images**, without retraining the full model from scratch.

---

## Why This Library?

Traditional Sri Lankan cooking — red curry, white curry, tempering — transforms vegetables so dramatically that standard food recognition models fail to identify them. This library lets you extend a model specifically built for that challenge, and adapt it to new vegetables with minimal data.

| Approach | Images needed | Time |
|---|---|---|
| Train from scratch | 500–1000+ per class | Days |
| **This library** | **20–50 per class** | **30–60 minutes** |

---

## Installation

```bash
pip install srilankan-food-trainer
```

**Requirements:** Python 3.8+, PyTorch 2.0+, internet connection on first run (downloads pre-trained model from Hugging Face automatically)

GPU is recommended but not required — CPU training works, just slower.

---

## Quick Start

```python
from srilankan_food_trainer import FoodModelExtender

# 1. Create extender — downloads pre-trained model automatically
extender = FoodModelExtender(verbose=True)

# 2. Add your class
#    ZIP filename becomes the class name:
#    e.g. potato_tempered.zip → class "potato_tempered"
extender.add_class("potato_tempered", "potato_tempered.zip", auto_extract=True)

# 3. Train (preserves original 8 classes + adds your new one)
extender.train(epochs=50)

# 4. Save
extender.save("extended_model.pth")
```

The saved model recognises all **9 classes** — original 8 + your new one.

---

## Step-by-Step Guide

### Step 1 — Prepare your images

Collect 30–50 images of your food class. Organise them in a folder, then zip it:

```
potato_tempered/          ← folder name = class name
├── image_001.jpg
├── image_002.jpg
├── image_003.jpg
└── ... (30–50 images)
```

```bash
zip -r potato_tempered.zip potato_tempered/
```

> **Important:** The ZIP filename becomes the class name. Use the format `vegetable_cookingstate` (e.g. `beetroot_white_curry.zip`).

---

### Step 2 — Initialise the extender

```python
from srilankan_food_trainer import FoodModelExtender

extender = FoodModelExtender(verbose=True)
# Output:
# 🚀 Sri Lankan Food Model Extender initialized!
#    Device: cuda
#    Base model: ranasinghehashini/srilankan-food-recognition
```

---

### Step 3 — Add your class

```python
extender.add_class(
    class_name="potato_tempered",
    images_path="potato_tempered.zip",
    auto_extract=True
)
# Output:
# 📸 Adding new class: potato_tempered
#    Found 37 images
#    Split complete:
#       Train: 25 images
#       Val:   5 images
#       Test:  7 images
```

The method automatically validates images, checks formats, and splits into train / validation / test sets (70% / 15% / 15%).

---

### Step 4 — Train

```python
results = extender.train(epochs=50, save_checkpoints=True)

print(f"Best validation accuracy: {results['best_val_acc']:.2f}%")
print(f"Training time: {results['total_time']/60:.1f} minutes")
```

Expected training time: **30–45 min** with GPU, **60–90 min** on CPU.

---

### Step 5 — Save and use

```python
extender.save("extended_model.pth")
```

Load it later with:

```python
import torch

checkpoint = torch.load("extended_model.pth")
# checkpoint contains:
# - model_state_dict   → neural network weights
# - original_classes   → the 8 original class names
# - new_classes        → your added class names
# - training_history   → loss and accuracy per epoch
# - base_model         → source model reference
# - timestamp          → when trained
```

---

## Image Requirements

| Requirement | Details |
|---|---|
| Minimum images | 20 per class |
| Recommended | 30–50 per class |
| Format | JPG or PNG |
| Resolution | Minimum 224 × 224 |
| Packaging | All images in one folder, zipped |
| ZIP naming | ZIP filename = class name |

**Tips for good results:**
- Use clear, well-lit photos
- Include different angles (top view, side view, close-up)
- Keep the subject consistent — all images should be the same food type and cooking state
- Remove blurry or dark images before zipping

---

## Naming Convention

Follow the same pattern as the original 8 classes — `vegetable_cookingstate`:

```
potato_tempered        ✅
beetroot_white_curry   ✅
lentil_red_curry       ✅
"Potato Curry"         ❌  spaces not allowed
potatocurry            ❌  missing underscore separator
```

---

## Pre-trained Model — Original 8 Classes

The model this library extends was trained on:

| # | Class | Vegetable | Cooking state |
|---|---|---|---|
| 1 | `carrot_raw` | Carrot | Raw |
| 2 | `carrot_white_curry` | Carrot | White curry (coconut milk) |
| 3 | `greenbeans_raw` | Green beans | Raw |
| 4 | `greenbeans_tempered` | Green beans | Tempered (high-heat stir-fry) |
| 5 | `greenbeans_white_curry` | Green beans | White curry (coconut milk) |
| 6 | `pumpkin_raw` | Pumpkin | Raw |
| 7 | `pumpkin_red_curry` | Pumpkin | Red curry (turmeric-based) |
| 8 | `pumpkin_white_curry` | Pumpkin | White curry (coconut milk) |

**Base model accuracy:** 90.25% validation · 84.91% full test · 87.75% few-shot test

---

## API Reference

### `FoodModelExtender(model_path=None, verbose=False)`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `model_path` | `str` or `None` | `None` | Path to local `.pth` checkpoint. If `None`, downloads pre-trained model automatically. |
| `verbose` | `bool` | `False` | Print detailed progress messages. |

---

### `.add_class(class_name, images_path, auto_extract=True)`

Registers a new food class for training.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `class_name` | `str` | — | Name for the new class. Should match ZIP filename. |
| `images_path` | `str` | — | Path to the ZIP file containing images. |
| `auto_extract` | `bool` | `True` | Automatically extract the ZIP file. |

Returns `True` on success, `False` on failure.

---

### `.train(epochs=50, save_checkpoints=True)`

Fine-tunes the model to include the new class.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `epochs` | `int` | `50` | Training rounds. Try 75–100 for low accuracy. |
| `save_checkpoints` | `bool` | `True` | Auto-save the best model during training. |

Returns a dict with `best_val_acc`, `total_time`, and `training_history`.

---

### `.save(output_path)`

Saves the extended model as a PyTorch `.pth` checkpoint.

| Parameter | Type | Description |
|---|---|---|
| `output_path` | `str` | Filename for the saved model (e.g. `extended_model.pth`). |

---

## Understanding Your Results

| Validation accuracy | Meaning |
|---|---|
| 90%+ | Excellent — very reliable |
| 85–90% | Very good — suitable for most applications |
| 80–85% | Good — consider adding more images |
| Below 80% | Needs improvement — see troubleshooting |

---

## Troubleshooting

**"Not enough images" error**
You need at least 20 images. Add more images and re-zip.

**"Model download failed" error**
Check your internet connection and re-run the cell. If it persists, restart your runtime.

**"Out of memory" error**
Restart your runtime and try again. Keep image count under 100 per class.

**Low accuracy (below 80%)**
- Add more high-quality images (aim for 50)
- Increase epochs to 75 or 100
- Check that all images are the same food type and cooking state
- Remove blurry or poorly lit images

**Wrong ZIP structure**

```
✅ Correct:                     ❌ Wrong:
potato_tempered.zip             potato_tempered.zip
└── potato_tempered/            ├── img1.jpg  ← images directly in ZIP
    ├── img1.jpg                └── img2.jpg
    └── img2.jpg
```

---

## Google Colab Tutorial

A complete step-by-step tutorial is available — no local setup needed:

📓 **[Open in Google Colab](https://colab.research.google.com/drive/1KNAjmstesJftJ_IgbihVj1pVRU_mgpsr?usp=sharing)**

The notebook covers:
1. Installing the library
2. Initialising the model extender
3. Uploading your images (ZIP upload via Colab)
4. Adding your class and validating images
5. Training the extended model
6. Saving and downloading the result

Expected total time: ~1 hour (including 30–60 min training).

---

## Related Resources

| Resource | Link |
|---|---|
| Pre-trained model | [Hugging Face — ranasinghehashini/srilankan-food-recognition](https://huggingface.co/ranasinghehashini/srilankan-food-recognition) |
| Training dataset | [Kaggle — Sri Lankan Food Recognition Dataset](https://www.kaggle.com/datasets/ranasinghehashini/sri-lankan-food-recognition-dataset) |
| Research | *A Transformation-Aware Deep Learning Approach for Recognizing Cooked Vegetable Ingredients in Sri Lankan Cuisine*, Ranasinghe G. H. C., 2026 |

---

## Citation

```bibtex
@misc{ranasinghe2026foodshot,
  author    = {Ranasinghe, G. H. C.},
  title     = {A Transformation-Aware Deep Learning Approach for Recognizing
               Cooked Vegetable Ingredients in Sri Lankan Cuisine},
  year      = {2026},
  note      = {BSc Hons in Computing, Coventry University / NIBM},
}
```

---

## License

MIT License — free to use, modify, and distribute with attribution.