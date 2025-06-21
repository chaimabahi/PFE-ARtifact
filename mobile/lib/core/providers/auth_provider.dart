import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user_model.dart';
import '../services/firestore_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error, verifying }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus _status = AuthStatus.initial;
  User? _firebaseUser;
  UserModel? _user;
  String _errorMessage = '';
  String? _verificationCode;
  String? _pendingEmail;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  Map<String, dynamic>? get userData => _user?.toMap();
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isProfileComplete => _user?.username?.isNotEmpty ?? false;
  bool get isPremium => _user?.plan == 'Premium';

  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        _status = AuthStatus.authenticated;
        await _loadUserData(user.uid);
      } else {
        _status = AuthStatus.unauthenticated;
        _user = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final userData = await _firestoreService.getUserData(uid);
      _user = userData != null ? UserModel.fromMap(userData) : UserModel(
        uid: uid,
        email: _firebaseUser?.email ?? '',
        plan: 'Basic',
        coins: 0,
        puzzleScore: 0,
        TotaleScore: 200,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to load user data';
      rethrow;
    }
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final querySnapshot = await _firestoreService.usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      _errorMessage = 'Error checking email existence: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> generateAndSendVerificationCode(String email) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final emailExists = await checkEmailExists(email);
      if (emailExists) {
        _status = AuthStatus.error;
        _errorMessage = 'Email already in use';
        notifyListeners();
        return;
      }

      _verificationCode = Random().nextInt(1000000).toString().padLeft(6, '0');
      _pendingEmail = email;

      final expiryTime = DateTime.now().add(const Duration(minutes: 15));
      final formattedExpiryTime = '${expiryTime.hour}:${expiryTime.minute} ${expiryTime.timeZoneName}, ${expiryTime.day} ${expiryTime.month}, ${expiryTime.year}';

      await _firestoreService.storeVerificationCode(email, _verificationCode!, expiryTime);

      await _sendEmailWithCode(email, _verificationCode!, formattedExpiryTime);

      _status = AuthStatus.verifying;
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to send verification code';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _sendEmailWithCode(String email, String code, String expiryTime) async {
    const String serverUrl = 'https://serverar-production.up.railway.app/send-verification-email';
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'passcode': code,
          'time': expiryTime,
        }),
      );

      if (response.statusCode != 200) {
        print('Server response body: ${response.body}');
        throw Exception('Failed to send email: ${response.body.isNotEmpty ? response.body : 'Unknown server error'}');
      }
    } catch (e) {
      print('Error sending email: $e');
      if (e.toString().contains('ProviderInstaller')) {
        throw Exception('Network security issue detected. Please update Google Play Services.');
      }
      rethrow;
    }
  }

  Future<bool> verifyCode(String code) async {
    try {
      final isValid = await _firestoreService.verifyCode(_pendingEmail!, code);
      if (isValid) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Invalid or expired verification code';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Error verifying code';
      notifyListeners();
      return false;
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message ?? 'An error occurred during sign in';
      rethrow;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _user = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          plan: 'Basic',
          coins: 0,
          puzzleScore: 0,
          TotaleScore: 200,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(_user!);
        await _auth.signOut();
        _status = AuthStatus.unauthenticated;
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message ?? 'An error occurred during sign up';
      rethrow;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      // Check if Google Play Services are available
      final isGooglePlayServicesAvailable = await GoogleSignIn().isSignedIn();
      if (!isGooglePlayServicesAvailable) {
        _status = AuthStatus.error;
        _errorMessage = 'Google Play Services not available';
        notifyListeners();
        return;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Google Sign-In failed - no user returned');
      }

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        _user = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          plan: 'Basic',
          coins: 0,
          puzzleScore: 0,
          TotaleScore: 200,
          createdAt: DateTime.now(),
        );
        await _firestoreService.createUser(_user!);
      } else {
        await _loadUserData(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _getGoogleSignInErrorMessage(e.code);
      notifyListeners();
      rethrow;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign in with Google: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  String _getGoogleSignInErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address';
      case 'invalid-credential':
        return 'The credential is malformed or has expired';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled in Firebase Console';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'user-not-found':
        return 'No user found for this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'network-request-failed':
        return 'Network error occurred';
      case 'internal-error':
        return 'Internal error occurred';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification ID';
      default:
        return 'Sign in failed. Please try again';
    }
  }

  Future<void> updateUserProfile({
    String? username,
    int? age,
    String? imageUrl,
    String? phoneNumber,
  }) async {
    try {
      if (_firebaseUser == null) return;

      _user = _user?.copyWith(
        username: username,
        age: age,
        imageUrl: imageUrl,
        phoneNumber: phoneNumber,
      );

      if (_user != null) {
        await _firestoreService.updateUserData(
          _firebaseUser!.uid,
          _user!.toMap(),
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to sign out';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    if (_firebaseUser != null) {
      await _loadUserData(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  void resetError() {
    _errorMessage = '';
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      _status = AuthStatus.authenticated;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message ?? 'An error occurred during password change';
      rethrow;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      // Check if email exists in Firestore
      final emailExists = await checkEmailExists(email);
      if (!emailExists) {
        _status = AuthStatus.error;
        _errorMessage = 'Email not found in our records';
        notifyListeners();
        return;
      }

      // Generate random 6-digit code
      _verificationCode = Random().nextInt(1000000).toString().padLeft(6, '0');
      _pendingEmail = email;

      // Calculate expiry time (15 minutes from now)
      final expiryTime = DateTime.now().add(const Duration(minutes: 15));
      final formattedExpiryTime = '${expiryTime.hour}:${expiryTime.minute} ${expiryTime.timeZoneName}, ${expiryTime.day} ${expiryTime.month}, ${expiryTime.year}';

      // Store verification code and expiry in Firestore
      await _firestoreService.storeVerificationCode(email, _verificationCode!, expiryTime);

      // Send email via Railway server
      await _sendPasswordResetEmailWithCode(email, _verificationCode!, formattedExpiryTime);

      _status = AuthStatus.verifying;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message ?? 'An error occurred sending password reset email';
      rethrow;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _sendPasswordResetEmailWithCode(String email, String code, String expiryTime) async {
    const String serverUrl = 'https://serverar-production.up.railway.app/send-password-reset-email';
    try {
      print('Sending password reset email to $email with code $code and time $expiryTime');
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'passcode': code,
          'time': expiryTime,
        }),
      );

      print('Server response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to send password reset email: ${response.body.isNotEmpty ? response.body : 'Unknown server error'}');
      }
    } catch (e) {
      print('Error sending password reset email: $e');
      if (e.toString().contains('ProviderInstaller')) {
        throw Exception('Network security issue detected. Please update Google Play Services.');
      }
      rethrow;
    }
  }

  Future<void> resetPasswordWithCode(String email, String code, String newPassword) async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      // Verify the code
      final isValid = await _firestoreService.verifyCode(email, code);
      if (!isValid) {
        _status = AuthStatus.error;
        _errorMessage = 'Invalid or expired verification code';
        notifyListeners();
        return;
      }

      // Call server-side endpoint to update password
      const String serverUrl = 'https://serverar-production.up.railway.app/reset-password';
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reset password: ${response.body.isNotEmpty ? response.body : 'Unknown server error'}');
      }

      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Failed to reset password: ${e.toString()}';
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}