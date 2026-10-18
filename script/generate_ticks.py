import wave, struct, math

def make(path, freq, amp):
    sr = 44100                 # sample rate: 44,100 samples per second (CD quality)
    n = int(sr * 0.05)         # length: 0.05 s = 50 ms -> 2,205 samples
    w = wave.open(path, 'w')
    w.setnchannels(1)          # mono
    w.setsampwidth(2)          # 16-bit audio
    w.setframerate(sr)
    frames = b''
    for i in range(n):
        t = i / sr                         # time of this sample in seconds
        env = math.exp(-t * 90)            # envelope: starts at 1, fades quickly
        value = amp * env * math.sin(2 * math.pi * freq * t)  # decaying sine wave
        frames += struct.pack('<h', int(32767 * value))       # convert to 16-bit
    w.writeframes(frames)
    w.close()

make('assets/audio/tick.wav', 1000, 0.6)
make('assets/audio/tick_accent.wav', 1600, 0.9)