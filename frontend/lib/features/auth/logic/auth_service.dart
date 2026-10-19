import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication & Cloud Firestore user synchronization service
class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  bool _isMobileInitialized = false;

  /// Reactive stream of the authenticated user
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Current authenticated Firebase user (or null)
  User? get currentUser => _firebaseAuth.currentUser;

  /// Retrieves the Firebase ID token for authenticating backend requests
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    return await currentUser?.getIdToken(forceRefresh);
  }

  /// Creates or updates the user profile document in Firestore at `users/{uid}`
  ///
  /// Stores only:
  /// - `uid`
  /// - `displayName`
  /// - `email`
  /// - `photoURL`
  /// - `createdAt` (preserved if document already exists)
  /// - `lastLoginAt` (updated with FieldValue.serverTimestamp())
  ///
  /// Uses `SetOptions(merge: true)` so existing fields (progress, XP, etc.) are never overwritten.
  Future<void> syncUserToFirestore(User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    debugPrint(
      '[AuthService] Fetching user profile document at users/${user.uid} before sync',
    );

    try {
      final userDoc = await userDocRef.get();
      final bool isFirstCreation = !userDoc.exists;

      final Map<String, dynamic> userData = {
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (isFirstCreation) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }

      // Debug log immediately before Firestore write
      debugPrint(
        '[AuthService] Initiating Firestore write to users/${user.uid} | isFirstCreation: $isFirstCreation | fields: ${userData.keys.toList()}',
      );

      await userDocRef.set(userData, SetOptions(merge: true));

      // Debug log immediately after Firestore write
      debugPrint(
        '[AuthService] Successfully completed Firestore write for UID: ${user.uid} to users/${user.uid}',
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '[AuthService] FirebaseException caught during Firestore write for UID: ${user.uid} | code: ${e.code} | message: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint(
        '[AuthService] General exception caught during Firestore write for UID: ${user.uid} | error: $e',
      );
      rethrow;
    }
  }

  /// Performs Google Sign-In targeting Flutter Web with mobile fallback
  ///
  /// On Web (Chrome): Uses the official Firebase Auth popup flow (`signInWithPopup`).
  /// On Mobile (Android): Uses `google_sign_in` package to obtain auth tokens and signs into Firebase.
  ///
  /// On successful authentication, automatically synchronizes the user profile to Firestore.
  /// If the Firestore write fails, the session is cleared and the error is rethrown
  /// to prevent a false success state.
  Future<UserCredential?> signInWithGoogle() async {
    UserCredential? credential;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      credential = await _firebaseAuth.signInWithPopup(googleProvider);
    } else {
      if (!_isMobileInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId:
              '534337065310-kh6tklf12sgpo13e3eadlstdacd06rf5.apps.googleusercontent.com',
        );
        _isMobileInitialized = true;
      }

      try {
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();

        final OAuthCredential oAuthCredential = GoogleAuthProvider.credential(
          idToken: googleUser.authentication.idToken,
        );

        credential = await _firebaseAuth.signInWithCredential(oAuthCredential);
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) {
          return null; // User cancelled account selection
        }
        rethrow;
      }
    }

    // Synchronize to Firestore on successful sign-in
    final user = credential.user;
    if (user != null) {
      debugPrint(
        '[AuthService] Google authentication successful for UID: ${user.uid}. Proceeding to Firestore user profile synchronization.',
      );
      try {
        await syncUserToFirestore(user);
        debugPrint(
          '[AuthService] Firestore user profile synchronization confirmed for UID: ${user.uid}.',
        );
      } on FirebaseException catch (firestoreError) {
        debugPrint(
          '[AuthService] Firestore sync failed for UID: ${user.uid} | code: ${firestoreError.code} | message: ${firestoreError.message}. Signing out to prevent inconsistent auth state.',
        );
        await _firebaseAuth.signOut();
        rethrow;
      } catch (e) {
        debugPrint(
          '[AuthService] Non-Firebase exception during Firestore sync for UID: ${user.uid} | error: $e. Signing out.',
        );
        await _firebaseAuth.signOut();
        rethrow;
      }
    }

    return credential;
  }

  /// Signs out the current user from Firebase and Google
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Ignore native signOut errors
      }
    }
  }
}
