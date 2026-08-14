import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AppSignInResult {
  const AppSignInResult({required this.userId, required this.isNewUser});

  final String userId;
  final bool isNewUser;
}

abstract class AppAuth {
  String? get currentUserId;

  Future<AppSignInResult> signInWithGoogle();

  Future<void> signOut();

  Future<void> deleteCurrentUser();
}

class FirebaseAppAuth implements AppAuth {
  FirebaseAppAuth({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  Future<void>? _googleInitialization;

  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  Future<void> _initializeGoogleSignIn() =>
      _googleInitialization ??= GoogleSignIn.instance.initialize();

  @override
  Future<AppSignInResult> signInWithGoogle() async {
    late final UserCredential credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters(const {'prompt': 'select_account'});
      credential = await _firebaseAuth.signInWithPopup(provider);
    } else {
      await _initializeGoogleSignIn();
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuthentication = googleUser.authentication;
      final firebaseCredential = GoogleAuthProvider.credential(
        idToken: googleAuthentication.idToken,
      );
      credential = await _firebaseAuth.signInWithCredential(firebaseCredential);
    }

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Google 로그인 결과에서 사용자 정보를 확인할 수 없습니다.',
      );
    }
    return AppSignInResult(
      userId: user.uid,
      isNewUser: credential.additionalUserInfo?.isNewUser ?? false,
    );
  }

  @override
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _initializeGoogleSignIn();
      await GoogleSignIn.instance.signOut();
    }
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) await user.delete();
    await signOut();
  }
}

/// Firebase가 초기화되지 않은 위젯 테스트에서만 사용하는 로그인 대체 구현입니다.
class PreviewAppAuth implements AppAuth {
  String? _userId;

  @override
  String? get currentUserId => _userId;

  @override
  Future<AppSignInResult> signInWithGoogle() async {
    _userId = 'preview-user';
    return const AppSignInResult(userId: 'preview-user', isNewUser: true);
  }

  @override
  Future<void> signOut() async => _userId = null;

  @override
  Future<void> deleteCurrentUser() async => _userId = null;
}
