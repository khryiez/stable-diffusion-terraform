#!/usr/bin/env bash

WORKSPACE="/home/ubuntu"
STABLE_DIFFUSION_WEBUI_VERSION="v1.8.0"
DREAMBOOTH_TAG="1.1.0"

echo "Install dependencies"
sudo apt update
sudo apt -y upgrade
sudo apt -y install jq \
        build-essential \
        software-properties-common \
        python3.10-venv \
        python3-pip \
        python3-tk \
        python3-dev \
        dos2unix \
        git \
        git-lfs \
        ncdu \
        nginx \
        net-tools \
        inetutils-ping \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        p7zip-full \
        htop \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 \
        libtcmalloc-minimal4 \
        apt-transport-https \
        ca-certificates \
        plocate && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

git lfs install

echo "Installing Github host keys"
ssh-keygen -R github.com
curl -L https://api.github.com/meta | jq -r '.ssh_keys | .[]' | sed -e 's/^/github.com /' >> ~/.ssh/known_hosts

echo "Cloning Stable Diffusion WebUI repo"
cd ${WORKSPACE}
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd ${WORKSPACE}/stable-diffusion-webui
echo "Checking out Stable Diffusion WebUI version: ${STABLE_DIFFUSION_WEBUI_VERSION}"
git checkout ${STABLE_DIFFUSION_WEBUI_VERSION}

echo "Installing ControlNet extension"
cd ${WORKSPACE}/stable-diffusion-webui/extensions
git clone https://github.com/Mikubill/sd-webui-controlnet.git

echo "Installing Dreambooth extension"
cd ${WORKSPACE}/stable-diffusion-webui/extensions
git clone https://github.com/d8ahazard/sd_dreambooth_extension.git
cd sd_dreambooth_extension
echo "Checking out Dreambooth commit: ${DREAMBOOTH_TAG}"
git checkout ${DREAMBOOTH_TAG}

echo "Install CUDA"
cd ${WORKSPACE}
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda
rm cuda-keyring_1.0-1_all.deb

echo "Check GPU"
lspci | grep -i nvidia
nvidia-smi

echo "Installing Pytorch"
pip3 install --no-cache-dir torch torchvision torchaudio

echo "Installing xformers"
pip3 install --no-cache-dir xformers

echo "Installing dependencies for the AUTOMATIC1111 WebUI"
cd ${WORKSPACE}/stable-diffusion-webui
python3 -m venv --system-site-packages venv
source venv/bin/activate
pip3 install wheel
pip3 install -r requirements.txt
pip3 install torch torchvision torchaudio
pip3 install xformers

echo "Installing dependencies for the Dreambooth extension"
cd ${WORKSPACE}/stable-diffusion-webui/extensions/sd_dreambooth_extension
pip3 install -r requirements.txt

echo "Installing dependencies for the ControlNet extension"
cd ${WORKSPACE}/stable-diffusion-webui/extensions/sd-webui-controlnet
pip3 install -r requirements.txt

echo "Adding configuration files for AUTOMATIC1111"
cp ${WORKSPACE}/stable-diffusion-terraform/config/config.json ${WORKSPACE}/stable-diffusion-webui/config.json
cp ${WORKSPACE}/stable-diffusion-terraform/config/ui-config.json ${WORKSPACE}/stable-diffusion-webui/ui-config.json
cp ${WORKSPACE}/stable-diffusion-terraform/config/webui-user.sh ${WORKSPACE}/stable-diffusion-webui/webui-user.sh

# Reboot for the Nvidia GPU to be used
sudo reboot
