"""
Default configuration for training
"""

class Config:
    """Default training configuration"""
    
    # Model settings
    REPO_ID = "ranasinghehashini/srilankan-food-recognition"
    EMBEDDING_DIM = 128
    
    # Training settings
    LEARNING_RATE = 0.00001
    NUM_EPOCHS = 50
    BATCH_SIZE = 8
    
    # Few-shot settings
    N_WAY = 2
    K_SHOT = 3
    Q_QUERY = 3
    EPISODES_PER_EPOCH = 100
    
    # Data split
    TRAIN_RATIO = 0.7
    VAL_RATIO = 0.15
    TEST_RATIO = 0.15
    
    # Image settings
    IMAGE_SIZE = 224
    NORMALIZE_MEAN = [0.485, 0.456, 0.406]
    NORMALIZE_STD = [0.229, 0.224, 0.225]
    
    # Minimum images required
    MIN_IMAGES = 20
    RECOMMENDED_IMAGES = 30
    
    def __init__(self, **kwargs):
        """Override defaults with custom values"""
        for key, value in kwargs.items():
            if hasattr(self, key):
                setattr(self, key, value)
            else:
                raise ValueError(f"Unknown config parameter: {key}")