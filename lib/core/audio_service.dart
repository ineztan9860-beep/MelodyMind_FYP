import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  // Use a pool of players so rapid/repeated taps always fire.
  // 8 players: even at the fastest Rhythm Challenge tempo a player is not
  // reused until its note (1.6 s) has finished, so notes never cut off.
  final List<AudioPlayer> _notePool = List.generate(8, (_) => AudioPlayer());
  int _notePoolIndex = 0;

  final AudioPlayer _sfxPlayer = AudioPlayer();

  // Separate low-latency pool for the Rhythm Challenge metronome,
  // so ticks never cut off note sounds (and vice versa).
  final List<AudioPlayer> _tickPool = List.generate(3, (_) => AudioPlayer());
  int _tickPoolIndex = 0;
  final AudioPlayer _bgmPlayer = AudioPlayer();

  bool isSoundEnabled = true;
  bool _bgmShouldPlay = false;

  /// Lets every sound in the app play at the same time. By default each
  /// Android player requests "audio focus", so starting one sound (e.g. a
  /// metronome tick) stops whichever sound was already playing (e.g. a
  /// note). Mixing removes that, so notes, ticks and music can overlap.
  static final AudioContext _mixContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  static const List<String> _preloadFiles = [
    'audio/note_C4.wav', 'audio/note_Cs4.wav', 'audio/note_D4.wav',
    'audio/note_Ds4.wav', 'audio/note_E4.wav', 'audio/note_F4.wav',
    'audio/note_Fs4.wav', 'audio/note_G4.wav', 'audio/note_Gs4.wav',
    'audio/note_A4.wav', 'audio/note_As4.wav', 'audio/note_B4.wav',
    'audio/tick.wav', 'audio/tick_accent.wav',
  ];

  AudioService() {
    AudioPlayer.global.setAudioContext(_mixContext).ignore();
    for (final p in [..._notePool, ..._tickPool, _sfxPlayer, _bgmPlayer]) {
      p.setAudioContext(_mixContext).ignore();
    }

    _bgmPlayer.setReleaseMode(ReleaseMode.loop).ignore();

    // Short sounds use low-latency mode: they start faster after a tap
    // and many can ring at once.
    for (final p in [..._notePool, ..._tickPool]) {
      p.setPlayerMode(PlayerMode.lowLatency).ignore();
      p.setReleaseMode(ReleaseMode.stop).ignore();
    }

    // Load the notes and ticks into memory up front, so the first tap
    // of a game does not lag while the file is read.
    AudioCache.instance.loadAll(_preloadFiles).ignore();
  }

  /// Metronome tick. [accent] is the louder click on the first beat
  /// of a bar. [volume] 0.0–1.0 (used for Hard mode's fade-out).
  Future<void> playTick({bool accent = false, double volume = 1.0}) async {
    if (!isSoundEnabled || volume <= 0) return;
    try {
      final player = _tickPool[_tickPoolIndex % _tickPool.length];
      _tickPoolIndex++;
      await player.stop();
      await player.play(
        AssetSource(accent ? 'audio/tick_accent.wav' : 'audio/tick.wav'),
        volume: volume,
      );
    } catch (e) {
      if (kDebugMode) print('❌ AudioService: Error playing tick: $e');
    }
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
    _bgmShouldPlay = true;
    if (!isSoundEnabled) {
      await stopBackgroundMusic();
      return;
    }
    try {
      if (kDebugMode) print('🔊 AudioService: Starting Background Music (Volume 0.08)');
      await _bgmPlayer.play(
          AssetSource(
              'audio/melancholic-piano-loop_89bpm_Csharp_major.wav'),
          volume: 0.08); // Reduced to gentle ambient level
    } catch (e) {
      if (kDebugMode) print('❌ AudioService: Error playing BGM: $e');
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      if (kDebugMode) print('🔊 AudioService: Pausing Background Music on background/minimize');
      await _bgmPlayer.pause();
    } catch (e) {
      if (kDebugMode) print('❌ AudioService: Error pausing BGM: $e');
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!isSoundEnabled || !_bgmShouldPlay) return;
    try {
      if (kDebugMode) print('🔊 AudioService: Resuming Background Music on app restore');
      await _bgmPlayer.resume();
    } catch (e) {
      await playBackgroundMusic();
    }
  }

  Future<void> stopBackgroundMusic() async {
    _bgmShouldPlay = false;
    await _bgmPlayer.stop();
  }

  /// Maps a note name to its sound file. All 12 notes are one octave,
  /// Middle C (C4) up to B4, matching where the notes sit on the treble
  /// stave in Note Identification. Tuned to A4 = 440 Hz.
  /// Recordings: Salamander Grand Piano by Alexander Holm (CC BY 3.0).
  String _mapNoteToFileName(String note) {
    const files = {
      'C': 'note_C4.wav',
      'C#': 'note_Cs4.wav',
      'D': 'note_D4.wav',
      'D#': 'note_Ds4.wav',
      'E': 'note_E4.wav',
      'F': 'note_F4.wav',
      'F#': 'note_Fs4.wav',
      'G': 'note_G4.wav',
      'G#': 'note_Gs4.wav',
      'A': 'note_A4.wav',
      'A#': 'note_As4.wav',
      'B': 'note_B4.wav',
    };
    return files[note.toUpperCase()] ?? 'note_C4.wav';
  }

  void dispose() {
    for (final p in _notePool) {
      p.dispose();
    }
    for (final p in _tickPool) {
      p.dispose();
    }
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}