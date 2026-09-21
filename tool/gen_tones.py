#!/usr/bin/env python3
"""Generate Waqt's built-in adhan/notification tones.

No third-party audio is bundled — every preset is synthesised here from pure
sine partials and shaped noise, so the tones are original and licence-free.
Outputs 16-bit PCM mono WAV files to both:

  assets/audio/                     (Flutter preview playback via audioplayers)
  android/app/src/main/res/raw/     (Android notification channel sound)

Run from the repo root:  python3 tool/gen_tones.py
"""

from __future__ import annotations

import math
import os
import struct
import wave

SR = 44100


def _env(i: int, n: int, attack: float = 0.01, release: float = 0.4) -> float:
    """Simple attack/release envelope in seconds."""
    a = int(attack * SR)
    r = int(release * SR)
    if i < a:
        return i / a
    if i > n - r:
        return max(0.0, (n - i) / r)
    return 1.0


def _note(freq: float, dur: float, harmonics=(1.0, 0.35, 0.12), vibrato=0.0) -> list[float]:
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        vib = 1.0 + vibrato * math.sin(2 * math.pi * 5.2 * t)
        s = 0.0
        for k, amp in enumerate(harmonics, start=1):
            s += amp * math.sin(2 * math.pi * freq * k * vib * t)
        out.append(s * _env(i, n))
    return out


def _bell(freq: float, dur: float) -> list[float]:
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        decay = math.exp(-3.0 * t)
        s = (
            math.sin(2 * math.pi * freq * t)
            + 0.5 * math.sin(2 * math.pi * freq * 2.01 * t)
            + 0.28 * math.sin(2 * math.pi * freq * 2.98 * t)
            + 0.15 * math.sin(2 * math.pi * freq * 4.2 * t)
        )
        out.append(s * decay * _env(i, n, attack=0.004, release=0.05))
    return out


def _wind(dur: float) -> list[float]:
    import random

    random.seed(7)
    n = int(dur * SR)
    raw = [random.uniform(-1, 1) for _ in range(n)]
    # Cheap moving-average low-pass to turn hiss into a soft gust.
    window = 60
    out = []
    acc = 0.0
    for i in range(n):
        acc += raw[i]
        if i >= window:
            acc -= raw[i - window]
        gust = 0.5 + 0.5 * math.sin(2 * math.pi * 0.35 * (i / SR))
        out.append((acc / window) * gust * 2.2)
    # Normalise and apply global envelope.
    peak = max(abs(v) for v in out) or 1.0
    return [v / peak * _env(i, n, attack=0.3, release=0.8) for i, v in enumerate(out)]


def _pluck(freq: float, dur: float) -> list[float]:
    """Short plucked-string tone (harp-like)."""
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        decay = math.exp(-6.0 * t)
        s = (
            math.sin(2 * math.pi * freq * t)
            + 0.3 * math.sin(2 * math.pi * freq * 2 * t)
            + 0.1 * math.sin(2 * math.pi * freq * 3 * t)
        )
        out.append(s * decay * _env(i, n, attack=0.002, release=0.05))
    return out


def _pad(freqs: tuple[float, ...], dur: float, attack=0.6, release=1.0) -> list[float]:
    """Slow, airy chord pad."""
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        shimmer = 0.8 + 0.2 * math.sin(2 * math.pi * 0.2 * t)
        s = sum(math.sin(2 * math.pi * f * t) for f in freqs)
        out.append(s / len(freqs) * shimmer * _env(i, n, attack=attack, release=release))
    return out


def _mix(layers: list[list[float]], total: float, offsets: list[float]) -> list[float]:
    n = int(total * SR)
    buf = [0.0] * n
    for layer, off in zip(layers, offsets):
        start = int(off * SR)
        for i, v in enumerate(layer):
            if start + i < n:
                buf[start + i] += v
    peak = max(abs(v) for v in buf) or 1.0
    return [v / peak * 0.85 for v in buf]


def _write(name: str, samples: list[float]) -> None:
    data = b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples)
    for directory in ("assets/audio", "android/app/src/main/res/raw"):
        os.makedirs(directory, exist_ok=True)
        with wave.open(os.path.join(directory, f"{name}.wav"), "wb") as fh:
            fh.setnchannels(1)
            fh.setsampwidth(2)
            fh.setframerate(SR)
            fh.writeframes(data)
    print(f"  {name}.wav  ({len(samples) / SR:.1f}s)")


def main() -> None:
    print("Generating Waqt tones...")

    # A calm three-phrase call (E4 -> A4 -> B4), vibrato like a distant muezzin.
    _write(
        "tone_traditional_adhan",
        _mix(
            [
                _note(329.63, 0.9, vibrato=0.004),
                _note(440.00, 0.9, vibrato=0.004),
                _note(493.88, 1.2, vibrato=0.004),
            ],
            total=3.0,
            offsets=[0.0, 0.85, 1.7],
        ),
    )

    # Soft repeating bell on G4.
    _write(
        "tone_mellow_bell",
        _mix([_bell(392.0, 1.0)] * 3, total=2.6, offsets=[0.0, 0.75, 1.5]),
    )

    # Bright two-note chime.
    _write(
        "tone_minimal_chime",
        _mix(
            [_bell(1318.51, 0.6), _bell(1975.53, 0.8)],
            total=1.4,
            offsets=[0.0, 0.35],
        ),
    )

    # Ambient gust for people who prefer no melody.
    _write("tone_desert_wind", _wind(2.8))

    # Gentle pentatonic arpeggio (C5 D5 E5 G5 A5).
    _write(
        "tone_nabawi_melody",
        _mix(
            [
                _note(523.25, 0.5),
                _note(587.33, 0.5),
                _note(659.25, 0.5),
                _note(783.99, 0.6),
                _note(880.00, 0.9),
            ],
            total=2.4,
            offsets=[0.0, 0.32, 0.64, 0.96, 1.3],
        ),
    )

    # Deep singing-bowl tone (110 Hz + fifths) with slow shimmer.
    _write(
        "tone_zen_bow",
        _mix(
            [
                _note(110.0, 3.0, harmonics=(1.0, 0.5, 0.3, 0.15), vibrato=0.002),
                _note(164.81, 3.0, harmonics=(0.6, 0.2), vibrato=0.002),
            ],
            total=3.0,
            offsets=[0.0, 0.0],
        ),
    )

    # Warm three-note dawn phrase (D4 -> F4 -> A4).
    _write(
        "tone_dawn_call",
        _mix(
            [
                _note(293.66, 0.9, vibrato=0.003),
                _note(349.23, 0.9, vibrato=0.003),
                _note(440.00, 1.3, vibrato=0.003),
            ],
            total=3.0,
            offsets=[0.0, 0.85, 1.7],
        ),
    )

    # Warm repeating bell on E4.
    _write(
        "tone_amber_bell",
        _mix([_bell(329.63, 1.0)] * 3, total=2.6, offsets=[0.0, 0.75, 1.5]),
    )

    # Ascending harp arpeggio (C5 E5 G5 C6).
    _write(
        "tone_soft_harp",
        _mix(
            [
                _pluck(523.25, 1.0),
                _pluck(659.25, 1.0),
                _pluck(783.99, 1.0),
                _pluck(1046.50, 1.2),
            ],
            total=2.4,
            offsets=[0.0, 0.28, 0.56, 0.84],
        ),
    )

    # Airy G-major pad (G3 B3 D4 G4).
    _write(
        "tone_medina_breeze",
        _pad((196.00, 246.94, 293.66, 392.00), 3.4, attack=0.7, release=1.2),
    )

    # Low drone A2 with a distant A4 chime.
    _write(
        "tone_night_calm",
        _mix(
            [
                _pad((110.0, 164.81), 3.4, attack=0.5, release=1.0),
                _bell(440.0, 1.2),
            ],
            total=3.4,
            offsets=[0.0, 0.9],
        ),
    )

    # Single deep gong (E2) with long tail.
    _write(
        "tone_tranquil_gong",
        _mix(
            [_note(82.41, 3.4, harmonics=(1.0, 0.6, 0.35, 0.2, 0.1), vibrato=0.001)],
            total=3.4,
            offsets=[0.0],
        ),
    )

    print("Done.")


if __name__ == "__main__":
    main()