from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="srilankan-food-trainer",
    version="0.2.1",
    author="Hashini Ranasinghe",
    description="Easy-to-use library for extending Sri Lankan food recognition models",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/ranasinghehashini/srilankan-food-trainer",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "Intended Audience :: Science/Research",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=[
        "torch>=2.0.0",
        "torchvision>=0.15.0",
        "Pillow>=9.0.0",
        "numpy>=1.21.0",
        "tqdm>=4.62.0",
        "requests>=2.28.0",
	"huggingface_hub>=0.19.0",
    ],
    keywords="food-recognition, deep-learning, pytorch, few-shot-learning, sri-lankan-food",
)