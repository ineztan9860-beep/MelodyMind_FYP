import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global provider that tracks the current bottom nav tab index.
/// Any screen can read/write this to switch tabs.
final navTabIndexProvider = StateProvider<int>((ref) => 0);
