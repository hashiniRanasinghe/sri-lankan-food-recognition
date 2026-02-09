# 🍛 Sri Lankan Food Trainer

Easy-to-use Python library for extending Sri Lankan food recognition models with your own classes!

## Installation
```bash
pip install srilankan-food-trainer
```

## Quick Start
```python
from srilankan_food_trainer import FoodModelExtender

# 1. Create extender
extender = FoodModelExtender()

# 2. Add your class
extender.add_class("potato_curry", "/path/to/images.zip")

# 3. Train
extender.train()

# 4. Save
extender.save("my_model.pth")
```

## Features

- ✅ Download pre-trained model automatically
- ✅ Add custom food classes with minimal code
- ✅ Few-shot learning support
- ✅ Easy model export

## Requirements

- Python 3.8+
- PyTorch 2.0+
- GPU recommended (but works on CPU)

## License

MIT License - see LICENSE file for details.