"""
Model architecture - same as original model
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class EmbeddingNet(nn.Module):
    """Neural network for creating food embeddings"""
    
    def __init__(self, embedding_dim=128):
        super(EmbeddingNet, self).__init__()
        
        self.conv1 = nn.Conv2d(3, 32, kernel_size=3, padding=1)
        self.bn1 = nn.BatchNorm2d(32)
        self.pool1 = nn.MaxPool2d(2, 2)
        
        self.conv2 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
        self.bn2 = nn.BatchNorm2d(64)
        self.pool2 = nn.MaxPool2d(2, 2)
        
        self.conv3 = nn.Conv2d(64, 128, kernel_size=3, padding=1)
        self.bn3 = nn.BatchNorm2d(128)
        self.pool3 = nn.MaxPool2d(2, 2)
        
        self.conv4 = nn.Conv2d(128, 256, kernel_size=3, padding=1)
        self.bn4 = nn.BatchNorm2d(256)
        self.pool4 = nn.MaxPool2d(2, 2)
        
        self.gap = nn.AdaptiveAvgPool2d(1)
        
        self.fc1 = nn.Linear(256, 256)
        self.dropout = nn.Dropout(0.3)
        self.fc2 = nn.Linear(256, embedding_dim)
    
    def forward(self, x):
        x = self.pool1(F.relu(self.bn1(self.conv1(x))))
        x = self.pool2(F.relu(self.bn2(self.conv2(x))))
        x = self.pool3(F.relu(self.bn3(self.conv3(x))))
        x = self.pool4(F.relu(self.bn4(self.conv4(x))))
        
        x = self.gap(x)
        x = x.view(x.size(0), -1)
        
        x = F.relu(self.fc1(x))
        x = self.dropout(x)
        embedding = self.fc2(x)
        
        return F.normalize(embedding, p=2, dim=1)


class PrototypicalNetwork(nn.Module):
    """Prototypical network wrapper"""
    
    def __init__(self, embedding_dim=128):
        super(PrototypicalNetwork, self).__init__()
        self.embedding_net = EmbeddingNet(embedding_dim)
    
    def forward(self, x):
        return self.embedding_net(x)