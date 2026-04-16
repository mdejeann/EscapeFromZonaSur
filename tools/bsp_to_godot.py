#!/usr/bin/env python3
"""
BSP to Godot converter.
Extracts geometry from Source Engine BSP files (Cambalache format),
exports as OBJ, then converts to GLB via Blender for Godot import.

The BSP files from cambalache-extracted use a non-standard lump header:
  (flag, file_offset, data_size, unused) instead of standard Source
  (file_offset, data_size, version, fourCC).

Usage:
    python tools/bsp_to_godot.py <bsp_file> [--output-dir assets/models/maps]
    python tools/bsp_to_godot.py --all
"""

import argparse
import os
import struct
import subprocess
import sys
from pathlib import Path


BSP_DIR = Path("/home/matias/cambalache-extracted/maps")
PROJECT_DIR = Path(__file__).resolve().parent.parent
DEFAULT_OUTPUT = PROJECT_DIR / "assets" / "models" / "maps"
BLENDER_BIN = "blender"

# Source BSP lump indices
LUMP_ENTITIES = 0
LUMP_PLANES = 1
LUMP_VERTICES = 3
LUMP_FACES = 7
LUMP_EDGES = 12
LUMP_SURFEDGES = 13
LUMP_MODELS = 14


def read_bsp_header(filepath):
    """Parse BSP header and return lump info dict."""
    with open(filepath, "rb") as f:
        ident = f.read(4)
        version = struct.unpack("<I", f.read(4))[0]
        if ident != b"VBSP":
            raise ValueError(f"Not a VBSP file: {ident}")

        lumps = {}
        for i in range(64):
            flag, offset, size, unused = struct.unpack("<IIII", f.read(16))
            lumps[i] = {"offset": offset, "size": size, "flag": flag}

    return version, lumps


def read_lump_data(filepath, lump_info):
    """Read raw lump data from file."""
    with open(filepath, "rb") as f:
        f.seek(lump_info["offset"])
        return f.read(lump_info["size"])


def parse_vertices(data):
    """Parse vertex data (3 floats per vertex)."""
    vertices = []
    num_verts = len(data) // 12
    for i in range(num_verts):
        x, y, z = struct.unpack_from("<fff", data, i * 12)
        # Source engine: Z-up to Y-up, inches to meters
        scale = 0.0254
        vertices.append((x * scale, z * scale, -y * scale))
    return vertices


def parse_edges(data):
    """Parse edge data (2 uint16 per edge)."""
    edges = []
    num_edges = len(data) // 4
    for i in range(num_edges):
        v0, v1 = struct.unpack_from("<HH", data, i * 4)
        edges.append((v0, v1))
    return edges


def parse_surfedges(data):
    """Parse surfedge data (1 int32 per surfedge)."""
    surfedges = []
    num_se = len(data) // 4
    for i in range(num_se):
        se = struct.unpack_from("<i", data, i * 4)[0]
        surfedges.append(se)
    return surfedges


def parse_faces(data):
    """Parse face data. Source BSP face struct = 56 bytes."""
    faces = []
    FACE_SIZE = 56
    num_faces = len(data) // FACE_SIZE
    for i in range(num_faces):
        off = i * FACE_SIZE
        # face struct: planenum(2) + side(1) + onNode(1) + firstedge(4) + numedges(2) + ...
        planenum = struct.unpack_from("<H", data, off)[0]
        side = data[off + 2]
        on_node = data[off + 3]
        first_edge = struct.unpack_from("<i", data, off + 4)[0]
        num_edges = struct.unpack_from("<h", data, off + 8)[0]
        faces.append({"first_edge": first_edge, "num_edges": num_edges})
    return faces


def extract_geometry(filepath, lumps):
    """Extract vertices, edges, surfedges and faces from BSP."""
    print("  Parsing vertices...")
    verts_data = read_lump_data(filepath, lumps[LUMP_VERTICES])
    vertices = parse_vertices(verts_data)
    print(f"    {len(vertices)} vertices")

    print("  Parsing edges...")
    edges_data = read_lump_data(filepath, lumps[LUMP_EDGES])
    edges = parse_edges(edges_data)
    print(f"    {len(edges)} edges")

    print("  Parsing surfedges...")
    se_data = read_lump_data(filepath, lumps[LUMP_SURFEDGES])
    surfedges = parse_surfedges(se_data)
    print(f"    {len(surfedges)} surfedges")

    print("  Parsing faces...")
    faces_data = read_lump_data(filepath, lumps[LUMP_FACES])
    raw_faces = parse_faces(faces_data)
    print(f"    {len(raw_faces)} raw faces")

    # Build triangulated face list
    triangles = []
    for face in raw_faces:
        first_edge = face["first_edge"]
        num_edges = face["num_edges"]
        if num_edges < 3:
            continue

        face_verts = []
        for i in range(num_edges):
            se_idx = first_edge + i
            if se_idx >= len(surfedges):
                break
            se = surfedges[se_idx]
            if se >= 0:
                if se < len(edges):
                    face_verts.append(edges[se][0])
            else:
                if abs(se) < len(edges):
                    face_verts.append(edges[abs(se)][1])

        if len(face_verts) >= 3:
            for j in range(1, len(face_verts) - 1):
                v0 = face_verts[0]
                v1 = face_verts[j]
                v2 = face_verts[j + 1]
                if v0 < len(vertices) and v1 < len(vertices) and v2 < len(vertices):
                    triangles.append((v0, v1, v2))

    print(f"    {len(triangles)} triangles")
    return vertices, triangles


def write_obj(vertices, faces, output_path):
    """Write vertices and faces to OBJ file."""
    with open(output_path, "w") as f:
        f.write(f"# BSP geometry export\n")
        f.write(f"# {len(vertices)} vertices, {len(faces)} faces\n\n")

        for v in vertices:
            f.write(f"v {v[0]:.6f} {v[1]:.6f} {v[2]:.6f}\n")

        f.write(f"\n")

        for face in faces:
            # OBJ is 1-indexed
            f.write(f"f {face[0]+1} {face[1]+1} {face[2]+1}\n")

    print(f"  Wrote OBJ: {output_path} ({os.path.getsize(output_path) / 1024:.0f} KB)")


def obj_to_glb(obj_path, glb_path):
    """Convert OBJ to GLB using Blender in headless mode."""
    blender_script = f"""
import bpy
import sys

# Clear scene
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()

# Import OBJ
bpy.ops.wm.obj_import(filepath=r"{obj_path}")

# Select all imported objects
bpy.ops.object.select_all(action='SELECT')

# Export as GLB
bpy.ops.export_scene.gltf(
    filepath=r"{glb_path}",
    export_format='GLB',
    use_selection=True,
    export_apply=True
)

print("Blender export complete: {glb_path}")
"""
    script_path = obj_path.replace(".obj", "_convert.py")
    with open(script_path, "w") as f:
        f.write(blender_script)

    try:
        result = subprocess.run(
            [BLENDER_BIN, "--background", "--python", script_path],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            print(f"  Blender error: {result.stderr[:500]}")
            return False
        print(f"  Wrote GLB: {glb_path}")
        return True
    except subprocess.TimeoutExpired:
        print("  Blender timed out")
        return False
    except FileNotFoundError:
        print(f"  Blender not found at: {BLENDER_BIN}")
        return False
    finally:
        if os.path.exists(script_path):
            os.remove(script_path)


def convert_bsp(bsp_path, output_dir):
    """Full conversion pipeline for a single BSP file."""
    bsp_path = Path(bsp_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    name = bsp_path.stem
    print(f"\n{'='*60}")
    print(f"Converting: {name}")
    print(f"{'='*60}")

    # Load BSP
    print(f"  Loading BSP ({bsp_path.stat().st_size / 1024 / 1024:.1f} MB)...")
    version, lumps = read_bsp_header(str(bsp_path))
    print(f"  BSP version: {version}")

    # Extract geometry
    vertices, faces = extract_geometry(str(bsp_path), lumps)

    if not vertices or not faces:
        print("  ERROR: No geometry extracted!")
        return False

    # Write OBJ
    obj_path = str(output_dir / f"{name}.obj")
    write_obj(vertices, faces, obj_path)

    # Convert to GLB via Blender
    glb_path = str(output_dir / f"{name}.glb")
    obj_to_glb(obj_path, glb_path)

    # Extract entities
    if lumps[LUMP_ENTITIES]["size"] > 0:
        ent_data = read_lump_data(str(bsp_path), lumps[LUMP_ENTITIES])
        entities_path = str(output_dir / f"{name}_entities.txt")
        with open(entities_path, "wb") as ef:
            ef.write(ent_data)
        print(f"  Wrote entities: {entities_path}")

    # Copy associated files
    import shutil
    nav_path = bsp_path.with_suffix(".nav")
    if nav_path.exists():
        shutil.copy2(str(nav_path), str(output_dir / nav_path.name))
        print(f"  Copied nav: {nav_path.name}")

    sounds_path = bsp_path.parent / f"{name}_level_sounds.txt"
    if sounds_path.exists():
        shutil.copy2(str(sounds_path), str(output_dir / sounds_path.name))
        print(f"  Copied sounds: {sounds_path.name}")

    return True


def main():
    parser = argparse.ArgumentParser(description="Convert BSP maps to Godot-compatible GLB")
    parser.add_argument("bsp_file", nargs="?", help="Path to BSP file")
    parser.add_argument("--all", action="store_true", help="Convert all BSPs from cambalache-extracted")
    parser.add_argument("--output-dir", default=str(DEFAULT_OUTPUT), help="Output directory")
    parser.add_argument("--obj-only", action="store_true", help="Only export OBJ, skip Blender conversion")
    args = parser.parse_args()

    if args.all:
        bsp_files = sorted(BSP_DIR.glob("*.bsp"))
        if not bsp_files:
            print(f"No BSP files found in {BSP_DIR}")
            sys.exit(1)
        print(f"Found {len(bsp_files)} BSP files")
        for bsp_file in bsp_files:
            convert_bsp(bsp_file, args.output_dir)
    elif args.bsp_file:
        convert_bsp(args.bsp_file, args.output_dir)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
