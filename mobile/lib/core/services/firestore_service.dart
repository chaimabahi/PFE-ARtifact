import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get supportCollection => _firestore.collection('support');

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await usersCollection.doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> storeVerificationCode(String email, String code, DateTime expiryTime) async {
    try {
      await _firestore.collection('verification_codes').doc(email).set({
        'code': code,
        'expiryTime': expiryTime,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyCode(String email, String code) async {
    try {
      final doc = await _firestore.collection('verification_codes').doc(email).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final storedCode = data['code'] as String;
      final expiryTime = (data['expiryTime'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiryTime)) {
        await _firestore.collection('verification_codes').doc(email).delete();
        return false;
      }

      return storedCode == code;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitSupportRequest({required String email, required String message}) async {
    try {
      await supportCollection.add({
        'email': email,
        'message': message,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      rethrow;
    }
  }
}