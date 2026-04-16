#!/bin/bash
# Launch Escape From Zona Sur with Vulkan on NVIDIA Optimus
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

GODOT="/home/matias/Godot_v4.6.2-stable_mono_linux_x86_64/Godot_v4.6.2-stable_mono_linux.x86_64"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

exec "$GODOT" --path "$PROJECT_DIR" "$@"
