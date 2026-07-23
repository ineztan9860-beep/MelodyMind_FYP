import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) => AudioService());

class GameState {
  final int score;
  final int totalAttempts;
  final String? currentTargetNote;
  final List<String> currentOptions;
  final bool isPlaying;

  const GameState({
    this.score = 0,
    this.totalAttempts = 0,
    this.currentTargetNote,
    this.currentOptions = const [],
    this.isPlaying = false,
  });

  GameState copyWith({
    int? score,
    int? totalAttempts,
    String? currentTargetNote,
    List<String>? currentOptions,
    bool? isPlaying,
  }) {
    return GameState(
      score: score ?? this.score,
      totalAttempts: totalAttempts ?? this.totalAttempts,
      currentTargetNote: currentTargetNote ?? this.currentTargetNote,
      currentOptions: currentOptions ?? this.currentOptions,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class GameEngineNotifier extends StateNotifier<GameState> {
  final AudioService _audioService;
  final List<String> _allNotes = ['C4', 'D4', 'E4', 'F4', 'G4', 'A4', 'B4', 'C5'];
  final _random = Random();

  GameEngineNotifier(this._audioService) : super(const GameState()) {
    _generateNextRound();
  }

  void _generateNextRound() {
    final targetNote = _allNotes[_random.nextInt(_allNotes.length)];
    
    // Generate 3 other random options
    final options = {targetNote};
    while (options.length < 4) {
      options.add(_allNotes[_random.nextInt(_allNotes.length)]);
    }
    
    final optionsList = options.toList()..shuffle(_random);
    
    state = state.copyWith(
      currentTargetNote: targetNote,
      currentOptions: optionsList,
      isPlaying: false,
    );
  }

  Future<void> playCurrentNote() async {
    if (state.currentTargetNote != null) {
      state = state.copyWith(isPlaying: true);
      await _audioService.playNote(state.currentTargetNote!);
      state = state.copyWith(isPlaying: false);
    }
  }

  void submitAnswer(String note) {
    if (state.currentTargetNote == null) return;
    
    bool isCorrect = note == state.currentTargetNote;
    state = state.copyWith(
      score: isCorrect ? state.score + 10 : state.score,
      totalAttempts: state.totalAttempts + 1,
    );
    _generateNextRound();
  }
}

final gameEngineProvider = StateNotifierProvider<GameEngineNotifier, GameState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return GameEngineNotifier(audioService);
});
