import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_models.dart';
import '../models/quiz_question_model.dart';

class QuizService {
  static const String historyCollection = 'quizze/history/themes';
  static const String geographyCollection = 'quizze/Geography/themes';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuizService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<QuizTheme>> getThemes(String category) {
    final collectionPath = category == 'History' ? historyCollection : geographyCollection;
    return _firestore.collection(collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => QuizTheme.fromFirestore(doc)).toList();
    });
  }

  Future<QuizTheme> getTheme(String category, String themeId) async {
    final collectionPath = category == 'History' ? historyCollection : geographyCollection;
    final doc = await _firestore.collection(collectionPath).doc(themeId).get();
    return QuizTheme.fromFirestore(doc);
  }

  Stream<List<String>> getLevels(String category, String themeId) {
    final collectionPath = category == 'History' ? historyCollection : geographyCollection;
    return _firestore
        .collection(collectionPath)
        .doc(themeId)
        .collection('levels')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<List<QuizQuestion>> getRandomQuestions(
      String category,
      String themeId,
      String levelId,
      int count,
      ) async {
    final collectionPath = category == 'History' ? historyCollection : geographyCollection;
    final querySnapshot = await _firestore
        .collection(collectionPath)
        .doc(themeId)
        .collection('levels')
        .doc(levelId)
        .collection('questions')
        .get();

    final allQuestions = querySnapshot.docs
        .map((doc) => QuizQuestion.fromFirestore(doc))
        .toList();

    allQuestions.shuffle();
    return allQuestions.take(count).toList();
  }

  Future<void> saveLevelCompletion(
      String category,
      String themeId,
      String levelId,
      int correctAnswers,
      int totalQuestions,
      ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('Cannot save progress: User not logged in');
      return;
    }

    try {
      // Calculate score percentage
      final scorePercentage = (correctAnswers / totalQuestions * 100);
      final isLevelPassed = scorePercentage >= 40;

      // Save in user's completed levels collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedLevels')
          .doc('$category-$themeId-$levelId')
          .set({
        'category': category,
        'themeId': themeId,
        'levelId': levelId,
        'completedAt': FieldValue.serverTimestamp(),
        'scorePercentage': scorePercentage,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
      });

      // Update user's progress summary
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        final completedLevels = (userData['completedLevelsCount'] ?? 0) + (isLevelPassed ? 1 : 0);
        final totaleScore = (userData['TotaleScore'] ?? 0) + (isLevelPassed ? 50 : 0);

        await _firestore.collection('users').doc(userId).update({
          'completedLevelsCount': completedLevels,
          'TotaleScore': totaleScore,
          'lastCompletedLevel': {
            'category': category,
            'themeId': themeId,
            'levelId': levelId,
            'completedAt': FieldValue.serverTimestamp(),
            'scorePercentage': scorePercentage,
          }
        });
      } else {
        // Create user document if it doesn't exist
        await _firestore.collection('users').doc(userId).set({
          'completedLevelsCount': isLevelPassed ? 1 : 0,
          'TotaleScore': isLevelPassed ? 50 : 0,
          'lastCompletedLevel': {
            'category': category,
            'themeId': themeId,
            'levelId': levelId,
            'completedAt': FieldValue.serverTimestamp(),
            'scorePercentage': scorePercentage,
          }
        });
      }

      // Unlock next level if score >= 40%
      if (isLevelPassed) {
        final levels = await _firestore
            .collection(category == 'History' ? historyCollection : geographyCollection)
            .doc(themeId)
            .collection('levels')
            .get();
        final levelIds = levels.docs.map((doc) => doc.id).toList()..sort();
        final currentLevelIndex = levelIds.indexOf(levelId);

        if (currentLevelIndex < levelIds.length - 1) {
          final nextLevelId = levelIds[currentLevelIndex + 1];
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('completedLevels')
              .doc('$category-$themeId-$nextLevelId')
              .set({
            'category': category,
            'themeId': themeId,
            'levelId': nextLevelId,
            'unlockedAt': FieldValue.serverTimestamp(),
            'isUnlocked': true,
          }, SetOptions(merge: true));
        }
      }

      print('Level completion saved successfully');
    } catch (e) {
      print('Error saving level completion: $e');
    }
  }

  Future<bool> isLevelCompleted(String category, String themeId, String levelId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedLevels')
          .doc('$category-$themeId-$levelId')
          .get();

      return doc.exists && (doc.data()?['scorePercentage'] ?? 0) >= 40;
    } catch (e) {
      print('Error checking level completion: $e');
      return false;
    }
  }

  Future<bool> isLevelUnlocked(String category, String themeId, String levelId) async {
    final collectionPath = category == 'History' ? historyCollection : geographyCollection;

    try {
      final levels = await _firestore
          .collection(collectionPath)
          .doc(themeId)
          .collection('levels')
          .get();

      final levelIds = levels.docs.map((doc) => doc.id).toList()..sort();
      final currentLevelIndex = levelIds.indexOf(levelId);

      if (currentLevelIndex == 0) return true;

      if (currentLevelIndex > 0) {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return false;

        final prevLevelDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('completedLevels')
            .doc('$category-$themeId-${levelIds[currentLevelIndex - 1]}')
            .get();

        return prevLevelDoc.exists &&
            (prevLevelDoc.data()?['isUnlocked'] == true ||
                (prevLevelDoc.data()?['scorePercentage'] ?? 0) >= 40);
      }

      return false;
    } catch (e) {
      print('Error checking if level is unlocked: $e');
      return false;
    }
  }

  Future<int> getUserCompletedLevelsCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      return userDoc.data()?['completedLevelsCount'] ?? 0;
    } catch (e) {
      print('Error getting completed levels count: $e');
      return 0;
    }
  }

  Future<int> getUserTotalScore() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;

      return userDoc.data()?['TotaleScore'] ?? 0;
    } catch (e) {
      print('Error getting total score: $e');
      return 0;
    }
  }

  Future<List<String>> getUserCompletedLevelIds(String category, String themeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedLevels')
          .where('category', isEqualTo: category)
          .where('themeId', isEqualTo: themeId)
          .get();

      return querySnapshot.docs.map((doc) {
        final docId = doc.id;
        final parts = docId.split('-');
        if (parts.length >= 3) {
          return parts[2];
        }
        return '';
      }).where((id) => id.isNotEmpty).toList();
    } catch (e) {
      print('Error getting completed level IDs: $e');
      return [];
    }
  }
}