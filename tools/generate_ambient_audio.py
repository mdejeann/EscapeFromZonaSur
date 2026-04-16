#!/usr/bin/env python3
"""Generate procedural ambient audio loops for Escape From Zona Sur.
Outputs OGG files via WAV intermediaries using numpy + soundfile.
Each ambient is ~30 seconds, loopable, mono, 44100 Hz.
"""
import numpy as np
import soundfile as sf
import subprocess
import os
import sys

SAMPLE_RATE = 44100
DURATION = 30  # seconds
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "audio", "ambient")


def noise(duration, sr=SAMPLE_RATE, color="pink"):
    """Generate colored noise."""
    n = int(duration * sr)
    white = np.random.randn(n).astype(np.float32)
    if color == "white":
        return white
    # Pink noise via spectral shaping
    freqs = np.fft.rfftfreq(n, 1.0 / sr)
    freqs[0] = 1.0  # avoid div by zero
    spectrum = np.fft.rfft(white)
    if color == "pink":
        spectrum /= np.sqrt(freqs)
    elif color == "brown":
        spectrum /= freqs
    result = np.fft.irfft(spectrum, n).astype(np.float32)
    return result / (np.max(np.abs(result)) + 1e-8)


def sine_wave(freq, duration, sr=SAMPLE_RATE):
    t = np.linspace(0, duration, int(sr * duration), endpoint=False, dtype=np.float32)
    return np.sin(2 * np.pi * freq * t)


def envelope(signal, attack=0.5, release=0.5, sr=SAMPLE_RATE):
    """Apply fade in/out."""
    n = len(signal)
    env = np.ones(n, dtype=np.float32)
    att = min(int(attack * sr), n // 2)
    rel = min(int(release * sr), n - att)
    if att > 0:
        env[:att] = np.linspace(0, 1, att)
    if rel > 0:
        env[-rel:] = np.linspace(1, 0, rel)
    return signal * env


def random_bird_chirps(duration, density=3, sr=SAMPLE_RATE):
    """Scatter short sine chirps to simulate birds."""
    out = np.zeros(int(duration * sr), dtype=np.float32)
    n_chirps = int(duration * density)
    for _ in range(n_chirps):
        freq = np.random.uniform(2000, 5500)
        chirp_dur = np.random.uniform(0.05, 0.3)
        chirp = sine_wave(freq, chirp_dur, sr) * 0.15
        # Frequency modulation
        mod = sine_wave(np.random.uniform(5, 20), chirp_dur, sr)
        chirp *= (0.5 + 0.5 * mod)
        chirp = envelope(chirp, 0.01, 0.05, sr)
        pos = int(np.random.uniform(0, duration - chirp_dur) * sr)
        end = min(pos + len(chirp), len(out))
        out[pos:end] += chirp[:end - pos]
    return out


def random_cricket_sounds(duration, density=5, sr=SAMPLE_RATE):
    """Simulate crickets with short high-freq bursts."""
    out = np.zeros(int(duration * sr), dtype=np.float32)
    n = int(duration * density)
    for _ in range(n):
        freq = np.random.uniform(4000, 7000)
        dur = np.random.uniform(0.3, 1.5)
        t = np.linspace(0, dur, int(sr * dur), endpoint=False, dtype=np.float32)
        cricket = np.sin(2 * np.pi * freq * t) * 0.08
        # Amplitude modulation (cricket-like pulsing)
        am_freq = np.random.uniform(15, 40)
        cricket *= (0.5 + 0.5 * np.sin(2 * np.pi * am_freq * t))
        cricket = envelope(cricket, 0.02, 0.02, sr)
        pos = int(np.random.uniform(0, max(0, duration - dur)) * sr)
        end = min(pos + len(cricket), len(out))
        out[pos:end] += cricket[:end - pos]
    return out


def wind_gusts(duration, sr=SAMPLE_RATE):
    """Slow-modulated brown noise for wind."""
    base = noise(duration, sr, "brown") * 0.3
    t = np.linspace(0, duration, int(duration * sr), endpoint=False, dtype=np.float32)
    # Slow modulation gives gusts
    mod = 0.4 + 0.6 * np.sin(2 * np.pi * 0.07 * t) * np.sin(2 * np.pi * 0.03 * t + 1.0)
    return base * mod


def dripping(duration, density=0.5, sr=SAMPLE_RATE):
    """Random water drip sounds."""
    out = np.zeros(int(duration * sr), dtype=np.float32)
    n = int(duration * density)
    for _ in range(n):
        freq = np.random.uniform(800, 2500)
        dur = np.random.uniform(0.02, 0.08)
        drip = sine_wave(freq, dur, sr) * 0.2
        drip = envelope(drip, 0.002, 0.03, sr)
        pos = int(np.random.uniform(0, duration - dur) * sr)
        end = min(pos + len(drip), len(out))
        out[pos:end] += drip[:end - pos]
    return out


def metal_creaks(duration, density=0.3, sr=SAMPLE_RATE):
    """Metallic creak sounds for abandoned areas."""
    out = np.zeros(int(duration * sr), dtype=np.float32)
    n = max(1, int(duration * density))
    for _ in range(n):
        freq = np.random.uniform(200, 800)
        dur = np.random.uniform(0.3, 1.2)
        t = np.linspace(0, dur, int(sr * dur), endpoint=False, dtype=np.float32)
        # Frequency sweep for creak effect
        sweep = np.sin(2 * np.pi * (freq + 200 * np.sin(2 * np.pi * 3 * t)) * t)
        sweep = (sweep * 0.1).astype(np.float32)
        sweep = envelope(sweep, 0.05, 0.1, sr)
        pos = int(np.random.uniform(0, max(0, duration - dur)) * sr)
        end = min(pos + len(sweep), len(out))
        out[pos:end] += sweep[:end - pos]
    return out


def generate_birds_suburban():
    """Green zone - peaceful suburban birds + light wind."""
    print("  Generating birds_suburban.ogg...")
    base = noise(DURATION, color="pink") * 0.04
    birds = random_bird_chirps(DURATION, density=4)
    crickets = random_cricket_sounds(DURATION, density=2)
    wind = wind_gusts(DURATION) * 0.3
    mix = base + birds + crickets * 0.5 + wind
    return envelope(mix, 2.0, 2.0)


def generate_suburban_desolate():
    """Residential - quiet, occasional creak, distant birds."""
    print("  Generating suburban_desolate.ogg...")
    base = noise(DURATION, color="brown") * 0.06
    wind = wind_gusts(DURATION) * 0.5
    birds = random_bird_chirps(DURATION, density=0.5) * 0.3
    creaks = metal_creaks(DURATION, density=0.2)
    mix = base + wind + birds + creaks
    return envelope(mix, 2.0, 2.0)


def generate_urban_abandoned():
    """Commercial center - wind through buildings, creaks, emptiness."""
    print("  Generating urban_abandoned.ogg...")
    base = noise(DURATION, color="brown") * 0.08
    wind = wind_gusts(DURATION) * 0.7
    creaks = metal_creaks(DURATION, density=0.5)
    # Low rumble
    rumble = sine_wave(35, DURATION) * 0.05
    mix = base + wind + creaks + rumble
    return envelope(mix, 2.0, 2.0)


def generate_train_wind():
    """Train station - strong wind, metal, hollow ambiance."""
    print("  Generating train_wind.ogg...")
    base = noise(DURATION, color="pink") * 0.05
    wind = wind_gusts(DURATION) * 0.8
    creaks = metal_creaks(DURATION, density=0.8)
    # Hollow resonance
    t = np.linspace(0, DURATION, SAMPLE_RATE * DURATION, endpoint=False, dtype=np.float32)
    hollow = np.sin(2 * np.pi * 120 * t) * 0.03 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.1 * t))
    mix = base + wind + creaks + hollow
    return envelope(mix, 2.0, 2.0)


def generate_hospital_eerie():
    """Hospital area - dripping, eerie tones, silence pressure."""
    print("  Generating hospital_eerie.ogg...")
    base = noise(DURATION, color="brown") * 0.03
    drips = dripping(DURATION, density=0.8)
    # Eerie tone cluster
    t = np.linspace(0, DURATION, SAMPLE_RATE * DURATION, endpoint=False, dtype=np.float32)
    eerie = (
        np.sin(2 * np.pi * 73 * t) * 0.02 +
        np.sin(2 * np.pi * 111 * t) * 0.015 +
        np.sin(2 * np.pi * 147 * t) * 0.01
    ).astype(np.float32)
    eerie *= (0.3 + 0.7 * np.sin(2 * np.pi * 0.05 * t))
    creaks = metal_creaks(DURATION, density=0.15)
    mix = base + drips + eerie + creaks
    return envelope(mix, 2.0, 2.0)


def generate_rain_light():
    """Light rain - pink noise filtered."""
    print("  Generating rain_light.ogg...")
    rain = noise(DURATION, color="pink") * 0.25
    # Modulate for variation
    t = np.linspace(0, DURATION, SAMPLE_RATE * DURATION, endpoint=False, dtype=np.float32)
    mod = 0.7 + 0.3 * np.sin(2 * np.pi * 0.04 * t)
    rain *= mod
    drips = dripping(DURATION, density=2.0) * 0.5
    mix = rain + drips
    return envelope(mix, 2.0, 2.0)


def generate_night_crickets():
    """Night time - crickets + very faint wind."""
    print("  Generating night_crickets.ogg...")
    base = noise(DURATION, color="brown") * 0.02
    crickets = random_cricket_sounds(DURATION, density=8)
    wind = wind_gusts(DURATION) * 0.15
    mix = base + crickets + wind
    return envelope(mix, 2.0, 2.0)


def normalize(audio, target_db=-18):
    """Normalize to target dB."""
    peak = np.max(np.abs(audio))
    if peak < 1e-8:
        return audio
    target_linear = 10 ** (target_db / 20)
    return audio * (target_linear / peak)


def save_ogg(audio, filename):
    """Save as WAV then convert to OGG with ffmpeg if available, else keep WAV."""
    wav_path = os.path.join(OUTPUT_DIR, filename.replace(".ogg", ".wav"))
    ogg_path = os.path.join(OUTPUT_DIR, filename)

    audio = normalize(audio)
    sf.write(wav_path, audio, SAMPLE_RATE)

    # Try converting to OGG
    try:
        subprocess.run(
            ["ffmpeg", "-y", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "4", ogg_path],
            capture_output=True, check=True
        )
        os.remove(wav_path)
        print(f"    Saved {ogg_path}")
    except (FileNotFoundError, subprocess.CalledProcessError):
        # ffmpeg not available, rename wav
        final = ogg_path.replace(".ogg", ".wav")
        print(f"    Saved {final} (ffmpeg not available for OGG conversion)")


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("Generating ambient audio for Escape From Zona Sur...")

    generators = [
        ("birds_suburban.ogg", generate_birds_suburban),
        ("suburban_desolate.ogg", generate_suburban_desolate),
        ("urban_abandoned.ogg", generate_urban_abandoned),
        ("train_wind.ogg", generate_train_wind),
        ("hospital_eerie.ogg", generate_hospital_eerie),
        ("rain_light.ogg", generate_rain_light),
        ("night_crickets.ogg", generate_night_crickets),
    ]

    for filename, gen_func in generators:
        audio = gen_func()
        save_ogg(audio, filename)

    print("\nDone! All ambient audio generated.")


if __name__ == "__main__":
    main()
