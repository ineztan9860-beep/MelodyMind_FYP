import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final highScoreRepositoryProvider = Provider((ref) => HighScoreRepository());

class HighScoreRepository {
  // Use a getter to avoid immediate crash if Firebase.initializeApp() is not called
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<void> saveHighScore(String playerName, int score) async {
    try {
      await _firestore.collection('High_Score').add({
        'playerName': playerName,
        'score': score,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Caught to handle local dev missing Firebase configuration
      debugPrint("Error saving high score (likely missing Firebase config): $e");
    }
  }

  Stream<QuerySnapshot>? getHighScores() {
    try {
      return _firestore
          .collection('High_Score')
          .orderBy('score', descending: true)
          .limit(10)
          .snapshots();
    } catch (e) {
      debugPrint("Firebase not configured: $e");
      return null;
    }
  }
}
