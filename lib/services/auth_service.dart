import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Authentication and user profile (Firebase Auth + Firestore).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<AppUser?> getCurrentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final ref = _firestore.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromMap({...doc.data()!, 'id': user.uid});
    }
    // Users created only in Firebase Auth (console, other clients) have no Firestore row yet.
    final appUser = AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
    await ref.set(appUser.toMap(), SetOptions(merge: true));
    return appUser;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    String? studentId,
    String? department,
    bool isAdmin = false,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user == null) return;
    await cred.user!.updateDisplayName(displayName);
    final appUser = AppUser(
      id: cred.user!.uid,
      email: email,
      displayName: displayName,
      studentId: studentId,
      department: department,
      isAdmin: isAdmin,
    );
    await _firestore.collection('users').doc(cred.user!.uid).set(appUser.toMap());
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateFcmToken(String? token) async {
    final user = _auth.currentUser;
    if (user != null && token != null) {
      await _firestore.collection('users').doc(user.uid).update({'fcmToken': token});
    }
  }
}
