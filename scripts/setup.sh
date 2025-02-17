#!/bin/bash

# rustc & cargo, etc.
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# pyenv
curl https://pyenv.run | bash
tee -a $HOME/.bashrc <<EOF
export PYENV_ROOT="\$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init -)"
EOF
source $HOME/.bashrc

# python 3.12
sudo apt update
sudo apt install libssl-dev zlib1g-dev python3-pip
pyenv install 3.12
pyenv global 3.12

# pip packages
pip3 install numpy matplotlib termcolor

# add just gpg
wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list

# apt install
sudo apt update
sudo apt install -y tree just default-jre liblog4j2-java protobuf-compiler