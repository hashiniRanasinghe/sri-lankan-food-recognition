"""
Main class for extending the food recognition model
"""

import os
import time
import zipfile
from datetime import datetime
import torch
import torch.optim as optim
from huggingface_hub import hf_hub_download
from tqdm import tqdm

from .model import PrototypicalNetwork
from .utils import (
    FoodDataset, split_dataset, create_episode,
    compute_prototypes, prototypical_loss, get_transforms
)
from .config import Config


class FoodModelExtender:
    """
    Easily extend the Sri Lankan Food Recognition model with your own classes.
    
    Example:
    --------
    >>> extender = FoodModelExtender()
    >>> extender.add_class("potato_tempered", "/path/to/images/")
    >>> extender.train()
    >>> extender.save("extended_model.pth")
    """
    
    def __init__(self, config=None, verbose=True):
        """
        Initialize the model extender
        
        Parameters:
        -----------
        config : Config, optional
            Custom configuration (uses defaults if None)
        verbose : bool
            Print progress messages
        """
        self.config = config or Config()
        self.verbose = verbose
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        
        self.model = None
        self.original_classes = []
        self.new_classes = []
        self.dataset_dir = None
        
        if self.verbose:
            print("🚀 Sri Lankan Food Model Extender initialized!")
            print(f"   Device: {self.device}")
            print(f"   Base model: {self.config.REPO_ID}")
    
    def download_pretrained(self):
        """Download the pre-trained model from Hugging Face"""
        
        if self.verbose:
            print("\n📥 Downloading pre-trained model...")
        
        try:
            model_path = hf_hub_download(
                repo_id=self.config.REPO_ID,
                filename="best_model.pth",
                cache_dir="/tmp/pretrained_model"
            )
            
            checkpoint = torch.load(model_path, map_location=self.device)
            
            self.model = PrototypicalNetwork(
                embedding_dim=self.config.EMBEDDING_DIM
            ).to(self.device)
            
            self.model.load_state_dict(checkpoint['model_state_dict'])
            self.original_classes = checkpoint['classes']
            
            if self.verbose:
                print(f"✅ Model downloaded successfully!")
                print(f"   Original classes: {len(self.original_classes)}")
                for cls in self.original_classes:
                    print(f"      - {cls}")
            
            return True
            
        except Exception as e:
            if self.verbose:
                print(f"❌ Error downloading model: {e}")
            return False
    
    def add_class(self, class_name, images_path, auto_extract=True):
        """
        Add a new class to train
        
        Parameters:
        -----------
        class_name : str
            Name of the new food class (e.g., "potato_tempered")
        images_path : str
            Path to folder containing images OR path to zip file
        auto_extract : bool
            Automatically extract if images_path is a zip file
        
        Returns:
        --------
        bool : Success status
        """
        
        if self.verbose:
            print(f"\n📸 Adding new class: {class_name}")
        
        # Handle zip files
        if images_path.endswith('.zip'):
            if auto_extract:
                if self.verbose:
                    print(f"   Extracting {images_path}...")
                
                extract_dir = os.path.join('/tmp', 'extracted_data')
                os.makedirs(extract_dir, exist_ok=True)
                
                with zipfile.ZipFile(images_path, 'r') as zip_ref:
                    zip_ref.extractall(extract_dir)
                
                # Find the class folder
                images_path = os.path.join(extract_dir, class_name)
                
                if not os.path.exists(images_path):
                    # Try to find any folder
                    folders = [f for f in os.listdir(extract_dir)
                              if os.path.isdir(os.path.join(extract_dir, f))]
                    if folders:
                        images_path = os.path.join(extract_dir, folders[0])
        
        # Verify images exist
        if not os.path.exists(images_path):
            if self.verbose:
                print(f"❌ Error: Path not found: {images_path}")
            return False
        
        # Count images
        image_files = [f for f in os.listdir(images_path)
                      if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
        
        if self.verbose:
            print(f"   Found {len(image_files)} images")
        
        # Check minimum requirement
        if len(image_files) < self.config.MIN_IMAGES:
            if self.verbose:
                print(f"⚠️  Warning: Only {len(image_files)} images found")
                print(f"   Minimum recommended: {self.config.RECOMMENDED_IMAGES}")
                print(f"   Continue? Training may have lower accuracy.")
        
        # Split dataset
        if self.dataset_dir is None:
            self.dataset_dir = '/tmp/dataset_split'
        
        if self.verbose:
            print(f"   Splitting into train/val/test...")
        
        train_count, val_count, test_count = split_dataset(
            images_path,
            self.dataset_dir,
            class_name,
            self.config.TRAIN_RATIO,
            self.config.VAL_RATIO
        )
        
        if self.verbose:
            print(f"   ✅ Split complete:")
            print(f"      Train: {train_count} images")
            print(f"      Val:   {val_count} images")
            print(f"      Test:  {test_count} images")
        
        self.new_classes.append(class_name)
        return True
    
    def train(self, epochs=None, save_checkpoints=True):
        """
        Train the model on new classes
        
        Parameters:
        -----------
        epochs : int, optional
            Number of training epochs (uses config default if None)
        save_checkpoints : bool
            Save model checkpoints during training
        
        Returns:
        --------
        dict : Training results
        """
        
        if self.model is None:
            if self.verbose:
                print("⚠️  Pre-trained model not loaded. Downloading...")
            if not self.download_pretrained():
                raise Exception("Failed to download pre-trained model")
        
        if not self.new_classes:
            raise Exception("No new classes added! Use add_class() first.")
        
        epochs = epochs or self.config.NUM_EPOCHS
        
        if self.verbose:
            print("\n" + "="*70)
            print("🚀 STARTING TRAINING")
            print("="*70)
            print(f"   New classes: {self.new_classes}")
            print(f"   Epochs: {epochs}")
            print(f"   Device: {self.device}")
            print("="*70 + "\n")
        
        # Load datasets
        train_dataset = FoodDataset(
            os.path.join(self.dataset_dir, 'train'),
            transform=None
        )
        
        val_dataset = FoodDataset(
            os.path.join(self.dataset_dir, 'val'),
            transform=None
        )
        
        train_transform, val_transform = get_transforms(self.config)
        
        # Setup optimizer
        optimizer = optim.Adam(
            self.model.parameters(),
            lr=self.config.LEARNING_RATE
        )
        
        scheduler = optim.lr_scheduler.StepLR(
            optimizer,
            step_size=epochs // 2,
            gamma=0.5
        )
        
        # Training loop
        best_val_acc = 0.0
        history = {
            'train_losses': [],
            'train_accs': [],
            'val_accs': []
        }
        
        start_time = time.time()
        
        for epoch in range(epochs):
            if self.verbose:
                print(f"\n📍 Epoch {epoch+1}/{epochs}")
            
            # Train
            train_loss, train_acc = self._train_epoch(
                train_dataset, train_transform, optimizer
            )
            
            # Validate
            val_acc = self._validate(val_dataset, val_transform)
            
            scheduler.step()
            
            # Save history
            history['train_losses'].append(train_loss)
            history['train_accs'].append(train_acc)
            history['val_accs'].append(val_acc)
            
            if self.verbose:
                print(f"   Train Loss: {train_loss:.4f}")
                print(f"   Train Acc:  {train_acc:.2f}%")
                print(f"   Val Acc:    {val_acc:.2f}%")
            
            # Save best model
            if val_acc > best_val_acc:
                best_val_acc = val_acc
                if save_checkpoints:
                    self._save_checkpoint(epoch, val_acc, history)
                
                if self.verbose:
                    print(f"   ✅ New best! ({val_acc:.2f}%)")
        
        total_time = time.time() - start_time
        
        if self.verbose:
            print("\n" + "="*70)
            print("🎉 TRAINING COMPLETE!")
            print("="*70)
            print(f"   Best Val Accuracy: {best_val_acc:.2f}%")
            print(f"   Total Time: {total_time/60:.1f} minutes")
            print("="*70)
        
        return {
            'best_val_acc': best_val_acc,
            'history': history,
            'total_time': total_time
        }
    
    def _train_epoch(self, dataset, transform, optimizer):
        """Train for one epoch"""
        self.model.train()
        epoch_losses = []
        correct, total = 0, 0
        
        pbar = tqdm(
            range(self.config.EPISODES_PER_EPOCH),
            desc="Training",
            disable=not self.verbose,
            ncols=100
        )
        
        for _ in pbar:
            support_imgs, support_lbls, query_imgs, query_lbls = create_episode(
                dataset,
                self.config.N_WAY,
                self.config.K_SHOT,
                self.config.Q_QUERY
            )
            
            support_tensors = torch.stack([transform(img) for img in support_imgs]).to(self.device)
            query_tensors = torch.stack([transform(img) for img in query_imgs]).to(self.device)
            support_labels = torch.tensor(support_lbls).to(self.device)
            query_labels = torch.tensor(query_lbls).to(self.device)
            
            support_embeddings = self.model(support_tensors)
            query_embeddings = self.model(query_tensors)
            
            prototypes, prototype_labels = compute_prototypes(support_embeddings, support_labels)
            loss = prototypical_loss(query_embeddings, prototypes, query_labels, prototype_labels)
            
            optimizer.zero_grad()
            loss.backward()
            optimizer.step()
            
            distances = torch.cdist(query_embeddings, prototypes)
            predictions = distances.argmin(dim=1)
            pred_labels = prototype_labels[predictions]
            
            correct += (pred_labels == query_labels).sum().item()
            total += len(query_labels)
            epoch_losses.append(loss.item())
            
            if self.verbose:
                pbar.set_postfix({
                    'loss': f'{loss.item():.4f}',
                    'acc': f'{100.0 * correct / total:.1f}%'
                })
        
        return sum(epoch_losses) / len(epoch_losses), 100.0 * correct / total
    
    def _validate(self, dataset, transform):
        """Validate the model"""
        self.model.eval()
        correct, total = 0, 0
        
        with torch.no_grad():
            for _ in range(50):
                support_imgs, support_lbls, query_imgs, query_lbls = create_episode(
                    dataset,
                    self.config.N_WAY,
                    self.config.K_SHOT,
                    self.config.Q_QUERY
                )
                
                support_tensors = torch.stack([transform(img) for img in support_imgs]).to(self.device)
                query_tensors = torch.stack([transform(img) for img in query_imgs]).to(self.device)
                support_labels = torch.tensor(support_lbls).to(self.device)
                query_labels = torch.tensor(query_lbls).to(self.device)
                
                support_embeddings = self.model(support_tensors)
                query_embeddings = self.model(query_tensors)
                
                prototypes, prototype_labels = compute_prototypes(support_embeddings, support_labels)
                
                distances = torch.cdist(query_embeddings, prototypes)
                predictions = distances.argmin(dim=1)
                pred_labels = prototype_labels[predictions]
                
                correct += (pred_labels == query_labels).sum().item()
                total += len(query_labels)
        
        return 100.0 * correct / total
    
    def _save_checkpoint(self, epoch, val_acc, history):
        """Save model checkpoint"""
        torch.save({
            'epoch': epoch,
            'model_state_dict': self.model.state_dict(),
            'val_acc': val_acc,
            'original_classes': self.original_classes,
            'new_classes': self.new_classes,
            'base_model': self.config.REPO_ID,
            'history': history,
        }, '/tmp/best_model.pth')
    
    def save(self, filepath="extended_model.pth"):
        """
        Save the extended model
        
        Parameters:
        -----------
        filepath : str
            Where to save the model
        """
        if self.model is None:
            raise Exception("No model to save! Train first.")
        
        checkpoint = torch.load('/tmp/best_model.pth')
        torch.save(checkpoint, filepath)
        
        if self.verbose:
            print(f"\n💾 Model saved to: {filepath}")
            print(f"   Original classes: {len(self.original_classes)}")
            print(f"   New classes: {len(self.new_classes)}")
            print(f"   Total: {len(self.original_classes) + len(self.new_classes)} classes")
        
        return filepath
    
    def predict(self, image_path):
        """
        Predict class for a single image
        
        Parameters:
        -----------
        image_path : str
            Path to image file
        
        Returns:
        --------
        dict : Prediction results
        """
        if self.model is None:
            raise Exception("Model not loaded! Train or load a model first.")
        
        from PIL import Image
        
        _, val_transform = get_transforms(self.config)
        
        img = Image.open(image_path).convert('RGB')
        img_tensor = val_transform(img).unsqueeze(0).to(self.device)
        
        self.model.eval()
        with torch.no_grad():
            embedding = self.model(img_tensor)
        
        return {
            'embedding': embedding.cpu().numpy(),
            'message': 'Embedding generated successfully'
        }