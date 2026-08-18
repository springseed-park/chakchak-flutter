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
  String? get currentUserDisplayName;
  String? get currentUserEmail;
  String? get currentUserPhotoUrl;

  Future<AppSignInResult> signInWithGoogle();

  /// Google Calendar 읽기 권한을 요청하고 짧게 유지되는 액세스 토큰을 반환합니다.
  /// 토큰은 저장하지 않고 캘린더 조회 요청에만 즉시 사용합니다.
  Future<String> authorizeGoogleCalendar();

  Future<void> signOut();

  Future<void> deleteCurrentUser();
}

class FirebaseAppAuth implements AppAuth {
  FirebaseAppAuth({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;
  Future<void>? _googleInitialization;
  GoogleSignInAccount? _googleAccount;
  String? _calendarAccessToken;

  static const _calendarScopes = <String>[
    'https://www.googleapis.com/auth/calendar.readonly',
  ];

  @override
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  @override
  String? get currentUserDisplayName => _firebaseAuth.currentUser?.displayName;

  @override
  String? get currentUserEmail => _firebaseAuth.currentUser?.email;

  @override
  String? get currentUserPhotoUrl => _firebaseAuth.currentUser?.photoURL;

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
      _googleAccount = googleUser;
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
  Future<String> authorizeGoogleCalendar() async {
    final cached = _calendarAccessToken;
    if (cached != null && cached.isNotEmpty) return cached;

    if (kIsWeb) {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw StateError('Google Calendar를 연결하려면 먼저 로그인해주세요.');
      }
      final provider = GoogleAuthProvider()
        ..addScope(_calendarScopes.first)
        ..setCustomParameters(const {'prompt': 'consent'});
      final credential = await user.reauthenticateWithPopup(provider);
      final token = credential.credential?.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Google Calendar 권한 토큰을 받지 못했어요.');
      }
      _calendarAccessToken = token;
      return token;
    }

    await _initializeGoogleSignIn();
    final account = _googleAccount ??
        await GoogleSignIn.instance.authenticate(scopeHint: _calendarScopes);
    _googleAccount = account;
    final authorization =
        await account.authorizationClient.authorizationForScopes(
              _calendarScopes,
            ) ??
            await account.authorizationClient.authorizeScopes(
              _calendarScopes,
            );
    _calendarAccessToken = authorization.accessToken;
    return authorization.accessToken;
  }

  @override
  Future<void> signOut() async {
    _calendarAccessToken = null;
    _googleAccount = null;
    if (!kIsWeb) {
      await _initializeGoogleSignIn();
      await GoogleSignIn.instance.signOut();
    }
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } on FirebaseAuthException catch (error) {
        if (error.code != 'requires-recent-login') rethrow;
        if (kIsWeb) {
          final provider = GoogleAuthProvider()
            ..setCustomParameters(const {'prompt': 'select_account'});
          await user.reauthenticateWithPopup(provider);
        } else {
          await _initializeGoogleSignIn();
          final googleUser = await GoogleSignIn.instance.authenticate();
          _googleAccount = googleUser;
          final googleAuthentication = googleUser.authentication;
          await user.reauthenticateWithCredential(
            GoogleAuthProvider.credential(
              idToken: googleAuthentication.idToken,
            ),
          );
        }
        await user.delete();
      }
    }
    await signOut();
  }
}

/// Firebase가 초기화되지 않은 위젯 테스트에서만 사용하는 로그인 대체 구현입니다.
class PreviewAppAuth implements AppAuth {
  String? _userId;

  @override
  String? get currentUserId => _userId;

  @override
  String? get currentUserDisplayName => _userId == null ? null : '착착 사용자';

  @override
  String? get currentUserEmail =>
      _userId == null ? null : 'preview@chakchak.app';

  @override
  String? get currentUserPhotoUrl => null;

  @override
  Future<AppSignInResult> signInWithGoogle() async {
    _userId = 'preview-user';
    return const AppSignInResult(userId: 'preview-user', isNewUser: true);
  }

  @override
  Future<String> authorizeGoogleCalendar() =>
      Future.error(StateError('미리보기 로그인에서는 Google Calendar를 연결할 수 없어요.'));

  @override
  Future<void> signOut() async => _userId = null;

  @override
  Future<void> deleteCurrentUser() async => _userId = null;
}

/// Firebase를 사용할 수 없는 실행 환경에서 가짜 로그인을 진행하지 않도록 막습니다.
class UnavailableAppAuth implements AppAuth {
  const UnavailableAppAuth();

  @override
  String? get currentUserId => null;

  @override
  String? get currentUserDisplayName => null;

  @override
  String? get currentUserEmail => null;

  @override
  String? get currentUserPhotoUrl => null;

  @override
  Future<AppSignInResult> signInWithGoogle() =>
      Future.error(StateError('Firebase 로그인을 준비하지 못했어요. 잠시 후 페이지를 새로고침해주세요.'));

  @override
  Future<String> authorizeGoogleCalendar() => Future.error(
      StateError('Firebase 로그인을 준비하지 못해 Google Calendar를 연결할 수 없어요.'));

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteCurrentUser() async {}
}
