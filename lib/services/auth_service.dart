import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<User> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user!;

    await user.updateDisplayName(username);

    await FirestoreService.createUserDocument(
      uid: user.uid,
      username: username,
      email: email,
    );

    return user;
  }

  static Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!;
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> updateEmail(String newEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
  }
}