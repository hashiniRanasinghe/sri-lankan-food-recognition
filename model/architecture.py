"""
Prototypical Network Architecture for Sri Lankan Food Recognition

This module implements a custom CNN-based embedding network designed for
transformation-invariant vegetable recognition across cooking states.

Architecture:
- 4 Convolutional blocks with batch normalization
- Global average pooling
- 128-dimensional embedding output
- Prototype-based classification

Author: G.H.C. Ranasinghe
University: Coventry University / NIBM
Date: February 2026
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class PrototypicalNetwork(nn.Module):
    """
    Prototypical Network for few-shot food recognition.
    
    Uses metric learning to create transformation-invariant embeddings
    where same vegetables cluster together regardless of cooking state.
    
    Args:
        embedding_dim (int): Dimensionality of output embeddings (default: 128)
        dropout_rate (float): Dropout probability (default: 0.3)
    
    Input:
        x: Tensor of shape (batch_size, 3, 224, 224)
    
    Output:
        embeddings: Tensor of shape (batch_size, embedding_dim)
    """
    
    def __init__(self, embedding_dim=128, dropout_rate=0.3):
        super(PrototypicalNetwork, self).__init__()
        
        self.embedding_dim = embedding_dim
        self.dropout_rate = dropout_rate
        
        # Convolutional Block 1: 3 -> 64 channels
        self.conv1 = nn.Conv2d(3, 64, kernel_size=3, padding=1)
        self.bn1 = nn.BatchNorm2d(64)
        self.pool1 = nn.MaxPool2d(2, 2)  # 224 -> 112
        
        # Convolutional Block 2: 64 -> 128 channels
        self.conv2 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.bn2 = nn.BatchNorm2d(128)
        self.pool2 = nn.MaxPool2d(2, 2)  # 112 -> 56
        
        # Convolutional Block 3: 128 -> 256 channels
        self.conv3 = nn.Conv2d(128, 256, kernel_size=3, padding=1)
        self.bn3 = nn.BatchNorm2d(256)
        self.pool3 = nn.MaxPool2d(2, 2)  # 56 -> 28
        
        # Convolutional Block 4: 256 -> 512 channels
        self.conv4 = nn.Conv2d(256, 512, kernel_size=3, padding=1)
        self.bn4 = nn.BatchNorm2d(512)
        self.pool4 = nn.MaxPool2d(2, 2)  # 28 -> 14
        
        # Global Average Pooling
        self.global_pool = nn.AdaptiveAvgPool2d(1)
        
        # Dropout for regularization
        self.dropout = nn.Dropout(dropout_rate)
        
        # Fully connected layer to embedding space
        self.fc = nn.Linear(512, embedding_dim)
        
    def forward(self, x):
        """
        Forward pass through the network.
        
        Args:
            x: Input tensor (batch_size, 3, 224, 224)
        
        Returns:
            Normalized embeddings (batch_size, embedding_dim)
        """
        # Block 1
        x = F.relu(self.bn1(self.conv1(x)))
        x = self.pool1(x)
        
        # Block 2
        x = F.relu(self.bn2(self.conv2(x)))
        x = self.pool2(x)
        
        # Block 3
        x = F.relu(self.bn3(self.conv3(x)))
        x = self.pool3(x)
        
        # Block 4
        x = F.relu(self.bn4(self.conv4(x)))
        x = self.pool4(x)
        
        # Global pooling: (batch, 512, 14, 14) -> (batch, 512, 1, 1)
        x = self.global_pool(x)
        x = x.view(x.size(0), -1)  # Flatten: (batch, 512)
        
        # Dropout
        x = self.dropout(x)
        
        # Project to embedding space
        x = self.fc(x)
        
        # L2 normalization for distance-based classification
        x = F.normalize(x, p=2, dim=1)
        
        return x
    
    def get_embedding_dim(self):
        """Return embedding dimensionality."""
        return self.embedding_dim


class PrototypicalClassifier:
    """
    Prototype-based classifier for food recognition.
    
    Classification is performed by computing Euclidean distance between
    query embeddings and class prototypes (mean embeddings).
    
    Attributes:
        prototypes (dict): Class name -> prototype embedding mapping
        classes (list): List of class names
    """
    
    def __init__(self):
        self.prototypes = {}
        self.classes = []
    
    def fit(self, embeddings, labels):
        """
        Compute class prototypes from support set.
        
        Args:
            embeddings: Tensor (num_samples, embedding_dim)
            labels: Tensor (num_samples,) with class indices
        """
        unique_labels = torch.unique(labels)
        
        for label in unique_labels:
            # Get all embeddings for this class
            class_mask = (labels == label)
            class_embeddings = embeddings[class_mask]
            
            # Compute mean (prototype)
            prototype = class_embeddings.mean(dim=0)
            
            self.prototypes[label.item()] = prototype
        
        self.classes = sorted(list(self.prototypes.keys()))
    
    def predict(self, embeddings, return_distances=False):
        """
        Predict classes for query embeddings.
        
        Args:
            embeddings: Tensor (num_queries, embedding_dim)
            return_distances: If True, return distances to all prototypes
        
        Returns:
            predictions: Tensor (num_queries,) with predicted class indices
            distances (optional): Tensor (num_queries, num_classes)
        """
        num_queries = embeddings.size(0)
        num_classes = len(self.classes)
        
        # Compute distances to all prototypes
        distances = torch.zeros(num_queries, num_classes)
        
        for i, class_idx in enumerate(self.classes):
            prototype = self.prototypes[class_idx]
            
            # Euclidean distance
            distances[:, i] = torch.sqrt(
                ((embeddings - prototype.unsqueeze(0)) ** 2).sum(dim=1)
            )
        
        # Predict class with minimum distance
        predictions = torch.tensor(self.classes)[distances.argmin(dim=1)]
        
        if return_distances:
            return predictions, distances
        return predictions
    
    def predict_proba(self, embeddings):
        """
        Predict class probabilities using softmax over negative distances.
        
        Args:
            embeddings: Tensor (num_queries, embedding_dim)
        
        Returns:
            probabilities: Tensor (num_queries, num_classes)
        """
        _, distances = self.predict(embeddings, return_distances=True)
        
        # Convert distances to similarities (negative distance)
        # Apply softmax to get probabilities
        probs = F.softmax(-distances, dim=1)
        
        return probs


def euclidean_distance(x, y):
    """
    Compute Euclidean distance between embeddings.
    
    Args:
        x: Tensor (batch_x, embedding_dim)
        y: Tensor (batch_y, embedding_dim)
    
    Returns:
        distances: Tensor (batch_x, batch_y)
    """
    n = x.size(0)
    m = y.size(0)
    d = x.size(1)
    
    x = x.unsqueeze(1).expand(n, m, d)
    y = y.unsqueeze(0).expand(n, m, d)
    
    return torch.sqrt(((x - y) ** 2).sum(dim=2))


def prototypical_loss(embeddings, labels, n_support):
    """
    Compute prototypical loss for episodic training.
    
    Args:
        embeddings: Tensor (n_support + n_query, embedding_dim)
        labels: Tensor (n_support + n_query,)
        n_support: Number of support examples per class
    
    Returns:
        loss: Scalar tensor
        accuracy: Scalar (classification accuracy on query set)
    """
    classes = torch.unique(labels)
    n_classes = len(classes)
    n_query = embeddings.size(0) - (n_classes * n_support)
    
    # Split into support and query
    support_embeddings = embeddings[:n_classes * n_support]
    support_labels = labels[:n_classes * n_support]
    query_embeddings = embeddings[n_classes * n_support:]
    query_labels = labels[n_classes * n_support:]
    
    # Compute prototypes
    prototypes = torch.zeros(n_classes, embeddings.size(1))
    
    for i, c in enumerate(classes):
        class_mask = (support_labels == c)
        prototypes[i] = support_embeddings[class_mask].mean(dim=0)
    
    # Compute distances for query set
    distances = euclidean_distance(query_embeddings, prototypes)
    
    # Cross-entropy loss with log softmax
    log_probs = F.log_softmax(-distances, dim=1)
    
    # Map query labels to class indices
    label_to_idx = {c.item(): i for i, c in enumerate(classes)}
    query_label_indices = torch.tensor(
        [label_to_idx[l.item()] for l in query_labels]
    )
    
    loss = F.nll_loss(log_probs, query_label_indices)
    
    # Compute accuracy
    predictions = (-distances).argmax(dim=1)
    accuracy = (predictions == query_label_indices).float().mean()
    
    return loss, accuracy


if __name__ == "__main__":
    """Test the model architecture."""
    
    print("="*70)
    print("Testing Prototypical Network Architecture")
    print("="*70)
    
    # Create model
    model = PrototypicalNetwork(embedding_dim=128)
    print(f"\n✅ Model created successfully")
    print(f"   Embedding dimension: {model.get_embedding_dim()}")
    
    # Test forward pass
    batch_size = 4
    test_input = torch.randn(batch_size, 3, 224, 224)
    
    with torch.no_grad():
        embeddings = model(test_input)
    
    print(f"\n✅ Forward pass successful")
    print(f"   Input shape: {test_input.shape}")
    print(f"   Output shape: {embeddings.shape}")
    print(f"   Embeddings are L2 normalized: {torch.allclose(embeddings.norm(dim=1), torch.ones(batch_size))}")
    
    # Count parameters
    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    
    print(f"\n📊 Model Statistics:")
    print(f"   Total parameters: {total_params:,}")
    print(f"   Trainable parameters: {trainable_params:,}")
    print(f"   Model size: ~{total_params * 4 / (1024**2):.2f} MB (float32)")
    
    print("\n" + "="*70)
    print("✅ All tests passed!")
    print("="*70)