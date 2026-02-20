# 🍛 Sri Lankan Food Trainer

Easy-to-use Python library for extending the Sri Lankan Food Recognition model with your own vegetable classes!

---

## Installation

```bash
pip install srilankan-food-trainer
```

---

## Quick Start

```python
from srilankan_food_trainer import FoodModelExtender

# 1. Create extender (downloads pre-trained model automatically)
extender = FoodModelExtender(verbose=True)

# 2. Add your class (ZIP filename = class name)
#    e.g. potato_tempered.zip → class name becomes "potato_tempered"
extender.add_class("potato_tempered", "potato_tempered.zip", auto_extract=True)

# 3. Train (preserves original 8 classes + adds your new one)
extender.train(epochs=50)

# 4. Save
extender.save("extended_model.pth")
```

The saved model will contain all **9 classes** (original 8 + your new one).

---

## How It Works

This library uses **transfer learning** on top of the pre-trained prototypical network published at [ranasinghehashini/srilankan-food-recognition](https://huggingface.co/ranasinghehashini/srilankan-food-recognition).

- The pre-trained model already knows how to recognise 8 vegetable-state combinations from Sri Lankan cuisine
- When you add a new class, the model **reuses** its existing transformation-invariant features
- Training only learns to distinguish the new class — the original 8 classes are preserved

---

## Image Requirements

| Requirement | Details |
|-------------|---------|
| **Minimum images** | 20 per class |
| **Recommended** | 30–50 per class |
| **Format** | JPG or PNG |
| **Resolution** | Minimum 224×224 |
| **Packaging** | All images inside a folder, zipped |
| **ZIP naming** | ZIP filename = class name (e.g. `potato_tempered.zip`) |

---

## Pre-trained Model — Original 8 Classes

The model this library extends was trained on:

| # | Class |
|---|-------|
| 1 | `carrot_raw` |
| 2 | `carrot_white_curry` |
| 3 | `greenbeans_raw` |
| 4 | `greenbeans_tempered` |
| 5 | `greenbeans_white_curry` |
| 6 | `pumpkin_raw` |
| 7 | `pumpkin_red_curry` |
| 8 | `pumpkin_white_curry` |

**Base model accuracy**: 90.25% validation / 84.91% full test / 87.75% few-shot test

---

## Full Example (Google Colab)

The complete step-by-step tutorial is available as a Colab notebook:

📓 `Sri_Lankan_Food_Trainer_Tutorial_Enhanced.ipynb`

Steps covered:
1. Install the library
2. Initialise the model extender
3. Upload your images (ZIP file via Colab file upload)
4. Add your class and validate images
5. Train the extended model
6. Save and download the extended model

---

## Requirements

- Python 3.8+
- PyTorch 2.0+
- GPU recommended (CPU works but training will be slower)
- Internet connection for first run (downloads pre-trained model from Hugging Face)

---

## License

MIT License — see LICENSE file for details.