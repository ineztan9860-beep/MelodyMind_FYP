import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('Users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Convert Firestore Timestamp to ISO string for easy transport
        final createdAt = data['createdAt'];
        if (createdAt != null && createdAt is Timestamp) {
          data['createdAtMs'] = createdAt.millisecondsSinceEpoch;
        } else {
          // Fall back to now if missing (existing accounts without the field)
          data['createdAtMs'] ??= DateTime.now().millisecondsSinceEpoch;
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
      return null;
    }
  }

  Future<void> createUserProfile(String uid, String email,
      {bool isGuest = false}) async {
    try {
      final now = DateTime.now();
      await _firestore.collection('Users').doc(uid).set({
        'uid': uid,
        'name': isGuest ? 'Guest' : email.split('@').first,
        'email': email,
        'level': 0,
        'xp': 0,
        'totalScore': 0,
        'streak': 1,
        'correctAnswers': 0,
        'totalAnswers': 0,
        'gamesPlayed': 0,
        'profileImageUrl': '',
        'isGuest': isGuest,
        'lastLoginDate': '${now.year}-${now.month}-${now.day}',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error creating user profile: $e");
    }
  }

  /// Call on every login to update the daily streak.
  Future<void> updateLoginStreak(String uid) async {
    try {
      final docRef = _firestore.collection('Users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        final lastLoginStr = data['lastLoginDate'] as String? ?? '';
        int currentStreak = data['streak'] ?? 0;

        int newStreak = currentStreak;

        if (lastLoginStr != todayStr) {
          if (lastLoginStr.isNotEmpty) {
            try {
              final parts = lastLoginStr.split('-');
              final lastLogin = DateTime(
                  int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              final diff = now.difference(lastLogin).inDays;
              if (diff == 1) {
                newStreak = currentStreak + 1;
              } else {
                newStreak = 1;
              }
            } catch (_) {
              newStreak = 1;
            }
          } else {
            newStreak = 1;
          }

          transaction.update(docRef, {
            'streak': newStreak,
            'lastLoginDate': todayStr,
          });
        } else if (currentStreak == 0) {
          transaction.update(docRef, {
            'streak': 1,
            'lastLoginDate': todayStr,
          });
        }
      });
    } catch (e) {
      debugPrint("Error updating login streak: $e");
    }
  }

  /// Called after each game to atomically update all stats.
  Future<void> updateGameStats({
    required String uid,
    required int scoreGained,
    required int xpGained,
    required int correctAnswers,
    required int totalAnswers,
    required bool incrementStreak,
  }) async {
    try {
      final docRef = _firestore.collection('Users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        int currentXp = data['xp'] ?? 0;
        int currentCorrect = data['correctAnswers'] ?? 0;
        int currentTotal = data['totalAnswers'] ?? 0;
        int currentScore = data['totalScore'] ?? 0;
        int currentGames = data['gamesPlayed'] ?? 0;

        int newXp = currentXp + xpGained;
        int newLevel = newXp ~/ 1000;
        int newCorrect = currentCorrect + correctAnswers;
        int newTotal = currentTotal + totalAnswers;
        int newScore = currentScore + scoreGained;

        transaction.update(docRef, {
          'xp': newXp,
          'level': newLevel,
          'totalScore': newScore,
          'correctAnswers': newCorrect,
          'totalAnswers': newTotal,
          'gamesPlayed': currentGames + 1,
        });
      });
    } catch (e) {
      debugPrint("Error updating game stats: $e");
    }
  }

  Future<void> addXP(String uid, int xpToAdd) async {
    try {
      final docRef = _firestore.collection('Users').doc(uid);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        int currentXp = snapshot.data()?['xp'] ?? 0;
        int newXp = currentXp + xpToAdd;
        int newLevel = newXp ~/ 1000;

        transaction.update(docRef, {
          'xp': newXp,
          'level': newLevel,
        });
      });
    } catch (e) {
      debugPrint("Error adding XP: $e");
    }
  }

  Future<void> updateProfileImage(String uid, String imageUrl) async {
    try {
      await _firestore.collection('Users').doc(uid).update({
        'profileImageUrl': imageUrl,
      });
    } catch (e) {
      debugPrint("Error updating profile image: $e");
    }
  }

  Future<void> resetProgress(String uid) async {
    try {
      await _firestore.collection('Users').doc(uid).update({
        'level': 0,
        'xp': 0,
        'totalScore': 0,
        'correctAnswers': 0,
        'totalAnswers': 0,
        'gamesPlayed': 0,
      });
    } catch (e) {
      debugPrint("Error resetting progress: $e");
    }
  }

  Future<void> updateName(String uid, String newName) async {
    try {
      await _firestore.collection('Users').doc(uid).update({
        'name': newName,
      });
    } catch (e) {
      debugPrint("Error updating name: $e");
    }
  }

  /// Returns a real-time stream of top [limit] players ordered by totalScore descending.
  Stream<List<Map<String, dynamic>>> getLeaderboardStream({int limit = 20}) {
    return _firestore
        .collection('Users')
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'uid': doc.id, ...doc.data()})
            .toList());
  }

  /// Send a friend request from [uid] to [targetUid].
  Future<void> sendFriendRequest(String uid, String targetUid) async {
    try {
      await _firestore
          .collection('Users')
          .doc(targetUid)
          .collection('friendRequests')
          .doc(uid)
          .set({
        'fromUid': uid,
        'status': 'pending',
        'sentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error sending friend request: $e");
    }
  }

  /// Check if a friend request has already been sent.
  Future<bool> hasSentFriendRequest(String uid, String targetUid) async {
    try {
      final doc = await _firestore
          .collection('Users')
          .doc(targetUid)
          .collection('friendRequests')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}
