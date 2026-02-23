# 📊 Sri Lankan Food Recognition Dataset

## Overview

This dataset contains images of Sri Lankan vegetables captured across different cooking transformation states. It is specifically designed to train models that can recognise vegetables despite dramatic visual changes caused by traditional Sri Lankan cooking methods.

- **Total Images**: 331
- **Classes**: 8 vegetable-state combinations across 3 vegetables
- **Split**: 230 training (69.5%) / 48 validation (14.5%) / 53 test (16.0%)
- **Images per class**: approximately 39–48

> ⚠️ Not every vegetable appears in all cooking states. This reflects authentic Sri Lankan culinary practice rather than a complete factorial design.

---

## 🎯 Dataset Purpose

Traditional food recognition systems fail on Sri Lankan cuisine because:
- **Turmeric** turns vegetables yellow-orange
- **Coconut milk** creates white/cream colouring
- **Chili powder** adds red tones
- **Frying/tempering** creates browned, caramelised surfaces
- **Curry preparation** softens vegetables and masks original colour

This dataset captures these post-cooking transformations to enable transformation-aware recognition.

---

## 📁 Dataset Structure

```
dataset/
├── train/                        # Training set (69.5% — 230 images)
│   ├── carrot_raw/               # 28 images
│   ├── carrot_white_curry/       # 28 images
│   ├── greenbeans_raw/           # 28 images
│   ├── greenbeans_tempered/      # 28 images
│   ├── greenbeans_white_curry/   # 27 images
│   ├── pumpkin_raw/              # 28 images
│   ├── pumpkin_red_curry/        # 33 images
│   └── pumpkin_white_curry/      # 30 images
│
├── val/                          # Validation set (14.5% — 48 images)
│   └── [same 8 class folders]
│
└── test/                         # Test set (16.0% — 53 images)
    └── [same 8 class folders]
```

---

## 🍽️ Classes

| # | Class | Total Images | Description |
|---|-------|-------------|-------------|
| 1 | `carrot_raw` | 40 | Fresh carrot — bright orange |
| 2 | `carrot_white_curry` | 40 | Carrot in coconut milk curry — cream coloured |
| 3 | `greenbeans_raw` | 41 | Fresh green beans — vibrant green |
| 4 | `greenbeans_tempered` | 40 | Stir-fried green beans — browned surfaces |
| 5 | `greenbeans_white_curry` | 39 | Green beans in coconut curry |
| 6 | `pumpkin_raw` | 40 | Fresh pumpkin — bright orange |
| 7 | `pumpkin_red_curry` | 48 | Pumpkin in turmeric curry — yellow-orange |
| 8 | `pumpkin_white_curry` | 43 | Pumpkin in coconut curry — cream coloured |
| | **Total** | **331** | |

---

## 🎨 Cooking Transformation States

### Raw State
- **Characteristics**: Original vegetable colour, fresh texture, high colour saturation
- **Examples**: Bright orange carrots, vibrant green beans, orange pumpkin

### Red Curry State
- **Ingredients**: Turmeric, curry powder, chili powder
- **Visual Changes**: Yellow-orange colouration from turmeric, softened texture
- **Classes**: `pumpkin_red_curry`

### White Curry State
- **Ingredients**: Coconut milk, small amount of turmeric
- **Visual Changes**: Cream/white colouration, smooth texture, original colour masked
- **Classes**: `carrot_white_curry`, `greenbeans_white_curry`, `pumpkin_white_curry`

### Tempered State
- **Method**: High-heat stir-frying with mustard seeds and curry leaves
- **Visual Changes**: Browned and caramelised surfaces, darkened colouring
- **Classes**: `greenbeans_tempered`

---

## 📥 Access Dataset

#### Kaggle
📊 **Kaggle Dataset**: [Dataset Page](https://www.kaggle.com/datasets/ranasinghehashini/sri-lankan-food-recognition-dataset/data)

---

## 🔍 Data Quality Control

### Collection Method
- **~40%** controlled captures: Vegetables prepared using authentic Sri Lankan recipes, photographed under standardised conditions
- **~60%** web scraping: Images from Sri Lankan recipe blogs, food social media accounts, and cooking websites (searched in both English and Sinhala)

### Inclusion Criteria
✅ Clear, focused images  
✅ Correct vegetable and cooking state verified  
✅ Authentic Sri Lankan preparation method  
✅ Minimal occlusion  
✅ Adequate lighting  
✅ Resolution ≥ 224×224  

### Exclusion Criteria
❌ Blurry or out-of-focus images  
❌ Incorrect or uncertain labels  
❌ Non-Sri Lankan cooking methods  
❌ Heavy watermarks  
❌ Duplicate images  
❌ Poor or inconsistent lighting  

---

## 🤝 Contributing

### Add More Images

Want to contribute to the dataset? Here's how:

1. **Capture Images**
   - Use authentic Sri Lankan recipes
   - Ensure good, consistent lighting
   - Multiple angles preferred (overhead, 45°, side)
   - Minimum 224×224 resolution
   - Aim for 30–50 images per class

2. **Label Correctly**
   - Use consistent naming: `{vegetable}_{state}_{id}.jpg`
   - Example: `carrot_white_curry_041.jpg`

3. **Submit**
   - Open a pull request with cooking method details and image count
   - All images will be quality-reviewed before inclusion

### Future Extensions

🔄 Planned additions:
- Additional vegetables: potato, eggplant (brinjal), bitter gourd (karawila), drumstick (murunga), cabbage
- Additional cooking states: mallum (shredded with grated coconut), boiled, steamed
- Regional variations in spice usage

---


<p align="center">
🍛 Preserving Sri Lankan culinary heritage through AI 🇱🇰
</p>
