"""
Sri Lankan Food Trainer
=======================

A simple library to extend the Sri Lankan Food Recognition model with your own classes.

Quick Start:
-----------
>>> from srilankan_food_trainer import FoodModelExtender
>>> 
>>> extender = FoodModelExtender()
>>> extender.add_class("potato_tempered", "/path/to/images/")
>>> extender.train()
>>> extender.save("my_extended_model.pth")

Author: Hashini Ranasinghe
License: MIT
"""

__version__ = "1.0.0"
__author__ = "Hashini Ranasinghe"

from .extender import FoodModelExtender
from .config import Config

__all__ = ['FoodModelExtender', 'Config']