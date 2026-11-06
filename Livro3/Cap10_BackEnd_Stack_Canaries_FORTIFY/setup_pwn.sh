#!/bin/bash
sudo apt update && sudo apt install python3-pip python3-venv \
    python3-dev git libssl-dev libffi-dev build-essential -y
python3 -m venv pwn_env
source pwn_env/bin/activate
pip install --upgrade pip && pip install pwntools
python3 -c "from pwn import *; print(pwnlib.util.fiddling.hexdump(b'PWN'))"
