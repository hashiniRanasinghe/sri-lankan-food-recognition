# 📊 Sri Lankan Food Recognition Dataset

## Overview

This dataset contains images of Sri Lankan vegetables captured across different cooking transformation states. It is specifically designed to train models that can recognize vegetables despite dramatic visual changes caused by traditional cooking methods.

---

## 🎯 Dataset Purpose

Traditional food recognition systems fail on Sri Lankan cuisine because:
- **Turmeric** turns vegetables yellow
- **Coconut milk** creates white/cream coloring
- **Chili powder** adds red tones
- **Frying/tempering** creates crispy surfaces
- **Curry preparation** softens vegetables

This dataset captures these transformations to enable transformation-aware recognition.

---

## 📁 Dataset Structure

```
dataset/
├── train/                    # Training set (70%)
│   ├── carrot_raw/
│   ├── carrot_white_curry/
│   ├── greenbeans_raw/
│   ├── greenbeans_tempered/
│   ├── greenbeans_white_curry/
│   ├── pumpkin_raw/
│   ├── pumpkin_red_curry/
│   └── pumpkin_white_curry/
│
├── val/                      # Validation set (15%)
│   └── [same structure]
│
└── test/                     # Test set (15%)
    └── [same structure]
```


## 🎨 Cooking Transformations

### Raw State
- **Characteristics**: Original vegetable color, fresh texture
- **Examples**: Orange carrots, green beans, orange pumpkin
- **Visual Features**: High color saturation, distinct shapes

### Red Curry State
- **Ingredients**: Turmeric, curry powder, chili powder
- **Visual Changes**: Yellow-orange color, softened texture
- **Examples**: Yellow-tinted vegetables in thick curry

### White Curry State
- **Ingredients**: Coconut milk, turmeric (small amount)
- **Visual Changes**: Cream/white color, smooth texture
- **Examples**: Pale vegetables in milky gravy

### Tempered State
- **Method**: High-heat stir-frying with spices
- **Visual Changes**: Browned surfaces, crispy edges
- **Examples**: Golden-brown vegetables with mustard seeds

---

## 📥 Access Dataset

#### Kaggle
📊 **Kaggle Dataset**: [Dataset Page](https://www.kaggle.com/datasets/ranasinghehashini/sri-lankan-food-recognition-dataset/data)

## 🔍 Data Quality Control

### Inclusion Criteria
✅ Clear, focused images  
✅ Correct vegetable and cooking state  
✅ Authentic Sri Lankan preparation  
✅ Minimal occlusion  
✅ Adequate lighting  
✅ Resolution ≥ 224x224  

### Exclusion Criteria
❌ Blurry or out-of-focus images  
❌ Incorrect labels  
❌ Non-Sri Lankan cooking methods  
❌ Heavy watermarks  
❌ Duplicate images  
❌ Poor lighting  

---

## 🤝 Contributing

### Add More Images
Want to contribute to the dataset? Here's how:

1. **Capture Images**
   - Use authentic Sri Lankan recipes
   - Ensure good lighting
   - Multiple angles preferred
   - Minimum 224x224 resolution

2. **Label Correctly**
   - Use consistent naming: `{vegetable}_{state}_{id}.jpg`
   - Example: `carrot_white_curry_001.jpg`

3. **Submit**
   - Open a pull request
   - Include cooking method details
   - Verify image quality

### Future Extensions
🔄 Planned additions:
- Potato (raw, curry, tempered)
- Cabbage (raw, mallum, curry)
- Brinjal (raw, tempered, curry)
- Tomato (raw, curry, chutney)
- More cooking states (boiled, steamed, fried)

---



## 📞 Contact

Questions about the dataset?

- **GitHub Issues**: [Report issues](https://github.com/yourusername/sri-lankan-food-recognition/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/sri-lankan-food-recognition/discussions)

---

<p align="center">
🍛 Preserving Sri Lankan culinary heritage through AI 🇱🇰
</p>