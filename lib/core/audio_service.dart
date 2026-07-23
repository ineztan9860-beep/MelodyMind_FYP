import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // Use a pool of players so rapid/repeated taps always fire
  final List<AudioPlayer> _notePool = List.generate(4, (_) => AudioPlayer());
  int _notePoolIndex = 0;

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool isSoundEnabled = true;

  AudioService() {
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playNote(String note) async {
    if (!isSoundEnabled) return;
    try {
      final String mappedNote = _mapNoteToFileName(note);
      if (kDebugMode) {
        print('🔊 AudioService: Playing note: $note ($mappedNote)');
      }
      // Round-robin through player pool so overlapping/rapid taps all sound
      final player = _notePool[_notePoolIndex % _notePool.length];
      _notePoolIndex++;
      await player.stop();
      await player.play(AssetSource('audio/$mappedNote'));
    } catch (e) {
      if (kDebugMode) print('❌ AudioService: Error playing Note: $e');
    }
  }

  Future<void> playSuccess() async {
    if (!isSoundEnabled) return;
    try {
      if (kDebugMode) print('🔊 AudioService: Playing Success SFX');
      await _sfxPlayer.stop();
      await _sfxPlayer.play(
          AssetSource('audio/success-notification_C_major.wav'));
    } catch (e) {
      if (kDebugMode) print('❌ AudioService: Error playing Success SFX: $e');
    }
  }

  Future<void> playError() async {
    if (!isSoundEnabled) return;
    try {
      if (kDebugMode) print('🔊 AudioService: Playing Error SFX');
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/windows-xp-error.wav'));
    } catch (e) {
      if (kDebugMode) print('❌ AudioService: Error playing Error SFX: $e');
    }
  }

  Future<void> playBackgroundMusic() async {
    if (!isSoundEnabled) {
      await stopBackgroundMusic();
      return;
    }
    try {
      if (kDebugMode) print('🔊 AudioService: Starting Background Music');
      await _bgmPlayer.play(
          AssetSource(
              'audio/melancholic-piano-loop_89bpm_Csharp_major.wav'),
          volume: 0.2);
    } catch (e) {
      if (kDebugMode) print('❌ AudioService: Error playing BGM: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    await _bgmPlayer.stop();
  }

  String _mapNoteToFileName(String note) {
    switch (note.toUpperCase()) {
      case 'C':
        return 'c.wav';
      case 'C#':
        return 'piano-c_Csharp_major.wav';
      case 'D':
        return 'd.wav';
      case 'D#':
        return 'piano-eb_Dsharp_major.wav';
      case 'E':
        return 'e.wav';
      case 'F':
        return 'f.wav';
      case 'F#':
        return 'piano-f_Fsharp_major.wav';
      case 'G':
        return 'g.wav';
      case 'G#':
        return 'piano-g_Gsharp_major.wav';
      case 'A':
        return 'a.wav';
      case 'A#':
        return 'piano-bb_Asharp_major.wav';
      case 'B':
        return 'b.wav';
      default:
        return 'c.wav';
    }
  }

  void dispose() {
    for (final p in _notePool) {
      p.dispose();
    }
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
