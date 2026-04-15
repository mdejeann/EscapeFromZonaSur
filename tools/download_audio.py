#!/usr/bin/env python3
"""
Download free audio assets from Freesound.org for Escape From Zona Sur.
Requires a Freesound API key: https://freesound.org/apiv2/apply/

Usage:
    python download_audio.py --api-key YOUR_KEY
    
Or set environment variable:
    export FREESOUND_API_KEY=YOUR_KEY
    python download_audio.py
"""

import json
import os
import sys
import urllib.request
import urllib.parse

API_BASE = "https://freesound.org/apiv2"
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST_PATH = os.path.join(PROJECT_ROOT, "assets", "audio", "audio_manifest.json")


def get_api_key():
    key = os.environ.get("FREESOUND_API_KEY", "")
    for i, arg in enumerate(sys.argv):
        if arg == "--api-key" and i + 1 < len(sys.argv):
            key = sys.argv[i + 1]
    if not key:
        print("ERROR: No API key. Set FREESOUND_API_KEY or use --api-key")
        print("Get one at: https://freesound.org/apiv2/apply/")
        sys.exit(1)
    return key


def search_and_download(query, target_path, api_key, max_results=1):
    """Search Freesound and download the best match."""
    params = urllib.parse.urlencode({
        "query": query,
        "filter": "license:\"Creative Commons 0\"",
        "sort": "rating_desc",
        "fields": "id,name,previews,license",
        "page_size": max_results,
        "token": api_key,
    })
    url = f"{API_BASE}/search/text/?{params}"

    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())

        if not data.get("results"):
            print(f"  No results for: {query}")
            return False

        sound = data["results"][0]
        preview_url = sound["previews"].get("preview-hq-ogg", sound["previews"].get("preview-lq-ogg", ""))

        if not preview_url:
            print(f"  No OGG preview for: {sound['name']}")
            return False

        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        print(f"  Downloading: {sound['name']} -> {os.path.basename(target_path)}")
        urllib.request.urlretrieve(preview_url, target_path)
        return True

    except Exception as e:
        print(f"  Error: {e}")
        return False


def download_by_id(sound_id, target_path, api_key):
    """Download a specific Freesound sound by ID."""
    url = f"{API_BASE}/sounds/{sound_id}/?fields=id,name,previews&token={api_key}"
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())

        preview_url = data["previews"].get("preview-hq-ogg", data["previews"].get("preview-lq-ogg", ""))
        if not preview_url:
            return False

        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        print(f"  Downloading ID {sound_id}: {data['name']} -> {os.path.basename(target_path)}")
        urllib.request.urlretrieve(preview_url, target_path)
        return True

    except Exception as e:
        print(f"  Error downloading ID {sound_id}: {e}")
        return False


def main():
    api_key = get_api_key()

    with open(MANIFEST_PATH, "r") as f:
        manifest = json.load(f)

    print("=== Downloading Ambient Sounds ===")
    for entry in manifest.get("ambient", []):
        target = entry["target_path"].replace("res://", os.path.join(PROJECT_ROOT, ""))
        if os.path.exists(target):
            print(f"  Skipping (exists): {entry['id']}")
            continue

        ids = entry.get("freesound_ids", [])
        if ids:
            download_by_id(ids[0], target, api_key)
        else:
            search_and_download(entry.get("freesound_search", entry["description"]), target, api_key)

    print("\n=== Downloading Footstep SFX ===")
    for entry in manifest.get("sfx_footsteps", []):
        base_dir = entry["target_path"].replace("res://", os.path.join(PROJECT_ROOT, ""))
        files_needed = entry.get("files_needed", 4)
        ids = entry.get("freesound_ids", [])

        for i in range(files_needed):
            target = os.path.join(base_dir, f"step_{i+1:02d}.ogg")
            if os.path.exists(target):
                continue
            if i < len(ids):
                download_by_id(ids[i], target, api_key)
            else:
                search_and_download(entry.get("freesound_search", entry["description"]), target, api_key)

    print("\n=== Downloading Environment SFX ===")
    for entry in manifest.get("sfx_environment", []):
        target = entry["target_path"].replace("res://", os.path.join(PROJECT_ROOT, ""))
        if os.path.exists(target):
            print(f"  Skipping (exists): {entry['id']}")
            continue
        search_and_download(entry.get("freesound_search", entry["description"]), target, api_key)

    print("\n=== Done! ===")
    print("Remember to also download the OpenGameArt Nature Sounds Pack:")
    for pack in manifest.get("opengameart_packs", []):
        print(f"  {pack['name']}: {pack['url']}")


if __name__ == "__main__":
    main()
