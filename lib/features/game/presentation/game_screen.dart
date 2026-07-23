import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/game_engine_provider.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameEngineProvider);
    final gameNotifier = ref.read(gameEngineProvider.notifier);

    // Provide a safe division for the percentage
    double correctPercentage = 0.0;
    if (gameState.totalAttempts > 0) {
      // Score is +10 per correct answer
      correctPercentage = (gameState.score / (gameState.totalAttempts * 10)).clamp(0.0, 1.0);
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Pitch Perfect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score & Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SCORE', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text('${gameState.score}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  CircularPercentIndicator(
                    radius: 30.0,
                    lineWidth: 6.0,
                    percent: correctPercentage,
                    center: Text(
                      "${(correctPercentage * 100).toInt()}%",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    progressColor: Colors.greenAccent,
                    backgroundColor: Colors.white24,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                ],
              ),
              const Spacer(),
              
              // Listen Button
              Center(
                child: GestureDetector(
                  onTap: gameState.isPlaying ? null : () => gameNotifier.playCurrentNote(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: gameState.isPlaying ? 110 : 120,
                    width:  gameState.isPlaying ? 110 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3B33D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: gameState.isPlaying ? 0.8 : 0.4),
                          blurRadius: gameState.isPlaying ? 30 : 20,
                          spreadRadius: gameState.isPlaying ? 10 : 5,
                        )
                      ],
                    ),
                    child: Icon(
                      gameState.isPlaying ? Icons.volume_up : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text('Tap to listen to the note', style: TextStyle(color: Colors.white54, fontSize: 16)),
              ),
              
              const Spacer(),
              
              // Multiple Choice Options
              const Text('Identify the note:', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Expanded(
                flex: 2,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: gameState.currentOptions.length,
                  itemBuilder: (context, index) {
                    final note = gameState.currentOptions[index];
                    return ElevatedButton(
                      onPressed: () => gameNotifier.submitAnswer(note),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        note,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
