import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../audio_service.dart';
import 'settings_provider.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  
  // Initialize with current setting
  final settings = ref.read(settingsProvider);
  service.isSoundEnabled = settings.isSoundEnabled;
  
  // Listen for changes
  ref.listen(settingsProvider, (previous, next) {
    service.isSoundEnabled = next.isSoundEnabled;
    if (next.isSoundEnabled) {
      service.playBackgroundMusic();
    } else {
      service.stopBackgroundMusic();
    }
  });

  ref.onDispose(() => service.dispose());
  return service;
});
