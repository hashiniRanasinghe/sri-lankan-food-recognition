"""
Helper functions for data processing and training
"""

import os
import random
import shutil
from PIL import Image
import torch
from torchvision import transforms
from torch.utils.data import Dataset
from tqdm import tqdm


class FoodDataset(Dataset):
    """Dataset class for loading food images"""
    
    def __init__(self, root_dir, transform=None):
        self.root_dir = root_dir
        self.transform = transform
        
        self.classes = sorted([d for d in os.listdir(root_dir)
                               if os.path.isdir(os.path.join(root_dir, d))
                               and not d.startswith('.')])
        
        self.class_to_idx = {cls: idx for idx, cls in enumerate(self.classes)}
        
        self.samples = []
        for class_name in self.classes:
            class_dir = os.path.join(root_dir, class_name)
            class_idx = self.class_to_idx[class_name]
            
            for img_name in os.listdir(class_dir):
                if img_name.lower().endswith(('.png', '.jpg', '.jpeg')):
                    img_path = os.path.join(class_dir, img_name)
                    self.samples.append((img_path, class_idx))
    
    def __len__(self):
        return len(self.samples)
    
    def __getitem__(self, idx):
        img_path, label = self.samples[idx]
        image = Image.open(img_path).convert('RGB')
        if self.transform:
            image = self.transform(image)
        return image, label


def split_dataset(source_dir, output_dir, class_name, train_ratio=0.7, val_ratio=0.15):
    """Split images into train/val/test"""
    
    # Create directories
    for split in ['train', 'val', 'test']:
        os.makedirs(os.path.join(output_dir, split, class_name), exist_ok=True)
    
    # Get all images
    images = [f for f in os.listdir(source_dir)
              if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
    
    # Shuffle
    random.seed(42)
    random.shuffle(images)
    
    # Split
    total = len(images)
    train_size = int(total * train_ratio)
    val_size = int(total * val_ratio)
    
    train_imgs = images[:train_size]
    val_imgs = images[train_size:train_size + val_size]
    test_imgs = images[train_size + val_size:]
    
    # Copy files
    for split, img_list in [('train', train_imgs), ('val', val_imgs), ('test', test_imgs)]:
        for img in img_list:
            src = os.path.join(source_dir, img)
            dst = os.path.join(output_dir, split, class_name, img)
            shutil.copy2(src, dst)
    
    return len(train_imgs), len(val_imgs), len(test_imgs)


def create_episode(dataset, n_way, k_shot, q_query):
    """Create a few-shot learning episode"""
    
    all_classes = list(range(len(dataset.classes)))
    selected_classes = random.sample(all_classes, min(n_way, len(all_classes)))
    
    class_samples = {cls: [] for cls in selected_classes}
    for img_path, label in dataset.samples:
        if label in selected_classes:
            class_samples[label].append(img_path)
    
    support_images, support_labels = [], []
    query_images, query_labels = [], []
    
    for cls_idx, cls in enumerate(selected_classes):
        available = len(class_samples[cls])
        needed = k_shot + q_query
        
        if available < needed:
            samples = random.choices(class_samples[cls], k=needed)
        else:
            samples = random.sample(class_samples[cls], needed)
        
        for path in samples[:k_shot]:
            img = Image.open(path).convert('RGB')
            support_images.append(img)
            support_labels.append(cls_idx)
        
        for path in samples[k_shot:]:
            img = Image.open(path).convert('RGB')
            query_images.append(img)
            query_labels.append(cls_idx)
    
    return support_images, support_labels, query_images, query_labels


def compute_prototypes(embeddings, labels):
    """Calculate class prototypes"""
    unique_labels = torch.unique(labels)
    prototypes = []
    
    for label in unique_labels:
        class_embeddings = embeddings[labels == label]
        prototype = class_embeddings.mean(dim=0)
        prototypes.append(prototype)
    
    return torch.stack(prototypes), unique_labels


def prototypical_loss(query_embeddings, prototypes, query_labels, prototype_labels):
    """Calculate prototypical loss"""
    distances = torch.cdist(query_embeddings, prototypes)
    logits = -distances
    
    targets = torch.zeros_like(query_labels)
    for i, label in enumerate(query_labels):
        targets[i] = (prototype_labels == label).nonzero(as_tuple=True)[0]
    
    return torch.nn.functional.cross_entropy(logits, targets)


def get_transforms(config):
    """Get data transforms"""
    
    train_transform = transforms.Compose([
        transforms.Resize((config.IMAGE_SIZE, config.IMAGE_SIZE)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15),
        transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.1),
        transforms.ToTensor(),
        transforms.Normalize(config.NORMALIZE_MEAN, config.NORMALIZE_STD)
    ])
    
    val_transform = transforms.Compose([
        transforms.Resize((config.IMAGE_SIZE, config.IMAGE_SIZE)),
        transforms.ToTensor(),
        transforms.Normalize(config.NORMALIZE_MEAN, config.NORMALIZE_STD)
    ])
    
    return train_transform, val_transform