#!/usr/bin/env python3
"""
Export .blend files from Assetsfree to .glb for Godot import.

Usage:
    /snap/bin/blender --background --python tools/export_blend_to_glb.py

Requires: Blender 4.2+ (snap version recommended: /snap/bin/blender)
"""
import bpy
import os
import sys

# Paths
ASSETS_SRC = os.path.expanduser("~/Documents/GitHub/Assetsfree")
PROJECT_DIR = os.path.expanduser("~/Documents/GitHub/EscapeFromZonaSur")

# Maps source .blend (relative to ASSETS_SRC) → output .glb (relative to PROJECT_DIR)
EXPORT_MAP = {
    "service_pistol_4k.blend/service_pistol_4k.blend": "assets/models/weapons/pistol/service_pistol.glb",
    "small_lpg_tank_4k.blend/small_lpg_tank_4k.blend": "assets/models/props/small_lpg_tank.glb",
}


def export_blend_to_glb(blend_path: str, glb_path: str) -> None:
    """Open a .blend file and export as .glb with downsized textures"""
    bpy.ops.wm.open_mainfile(filepath=blend_path)

    # Downscale all images to max 1024px to keep .glb small for Godot import
    for img in bpy.data.images:
        if img.size[0] > 1024 or img.size[1] > 1024:
            img.scale(1024, 1024)

    os.makedirs(os.path.dirname(glb_path), exist_ok=True)

    bpy.ops.export_scene.gltf(
        filepath=glb_path,
        export_format='GLB',
        export_texcoords=True,
        export_normals=True,
        export_materials='EXPORT',
        export_image_format='JPEG',
        export_apply=True,
        export_image_quality=60,
    )
    print(f"Exported: {glb_path}")


def main():
    for blend_rel, glb_rel in EXPORT_MAP.items():
        blend_path = os.path.join(ASSETS_SRC, blend_rel)
        glb_path = os.path.join(PROJECT_DIR, glb_rel)

        if not os.path.exists(blend_path):
            print(f"SKIP (not found): {blend_path}")
            continue

        export_blend_to_glb(blend_path, glb_path)

    print("\nDone! Re-open Godot to import the .glb files.")


if __name__ == "__main__":
    main()
