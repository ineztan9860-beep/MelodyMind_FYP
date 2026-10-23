"""Make the quiet background music file used by MelodyMind (bgm_soft.wav).

The app's original background loop was played at 8% volume in code.
Safari on iPhone ignores volume settings, so on iPhone it played at full
volume and drowned out the game notes. This script builds the 8% level
into the file itself, so the music stays soft on every device. It also
mixes stereo down to mono, which halves the file size.

Uses only Python's standard library (no extra installs).

Usage (run from the repo folder):
    python script/make_bgm_soft.py path/to/original_loop.wav
"""
import array
import sys
import wave

GAIN = 0.08  # 8% volume, the level the app used before (volume: 0.08)
DEFAULT_SOURCE = "melancholic-piano-loop_89bpm_Csharp_major.wav"
OUTPUT = "assets/audio/bgm_soft.wav"


def make_bgm_soft(source, output, gain=GAIN):
    with wave.open(source, "rb") as src:
        channels = src.getnchannels()
        rate = src.getframerate()
        if src.getsampwidth() != 2:
            raise ValueError("Expected a 16-bit WAV file")
        samples = array.array("h", src.readframes(src.getnframes()))
    if sys.byteorder == "big":  # WAV data is little-endian
        samples.byteswap()

    quiet = array.array("h")
    for i in range(0, len(samples), channels):
        frame = samples[i:i + channels]
        mono = sum(frame) / channels          # stereo -> mono (average)
        value = int(mono * gain)              # turn down to 8%
        quiet.append(max(-32768, min(32767, value)))

    if sys.byteorder == "big":
        quiet.byteswap()
    with wave.open(output, "wb") as out:
        out.setnchannels(1)    # mono
        out.setsampwidth(2)    # 16-bit
        out.setframerate(rate)
        out.writeframes(quiet.tobytes())
    print(f"Saved {output}: {len(quiet) / rate:.1f} s, mono, {rate} Hz")


if __name__ == "__main__":
    make_bgm_soft(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SOURCE, OUTPUT)
