import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileStore {
  UserProfileStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _onboardingKey(String userId) =>
      'chakchak.onboarding.completed.$userId';
  String _consentKey(String userId) => 'chakchak.consent.accepted.$userId';
  String _heightKey(String userId) => 'chakchak.profile.height.$userId';
  String _weightKey(String userId) => 'chakchak.profile.weight.$userId';
  String _genderKey(String userId) => 'chakchak.profile.gender.$userId';
  String _basicWardrobeKey(String userId) =>
      'chakchak.wardrobe.useBasicItems.$userId';

  Future<bool> hasAcceptedTerms(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final localAccepted = preferences.getBool(_consentKey(userId)) ?? false;
    if (localAccepted) return true;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 3));
      final accepted = snapshot.data()?['consentAccepted'] == true;
      if (accepted) {
        await preferences.setBool(_consentKey(userId), true);
        return true;
      }
    } on FirebaseException catch (_) {
      // Firestore가 준비되지 않은 환경에서는 기기 캐시를 사용합니다.
    } on TimeoutException catch (_) {
      // Firestore가 준비되지 않은 환경에서는 기기 캐시를 사용합니다.
    }
    return false;
  }

  Future<void> markTermsAccepted(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_consentKey(userId), true);
    try {
      await _firestore.collection('users').doc(userId).set({
        'consentAccepted': true,
        'consentAcceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
    } on FirebaseException catch (_) {
      // Firestore 활성화 전에도 로컬 동의 상태를 유지합니다.
    } on TimeoutException catch (_) {
      // Firestore 활성화 전에도 로컬 동의 상태를 유지합니다.
    }
  }

  Future<bool> hasCompletedOnboarding(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final localCompleted = preferences.getBool(_onboardingKey(userId)) ?? false;
    if (localCompleted) return true;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 3));
      final completed = snapshot.data()?['onboardingCompleted'] == true;
      if (completed) {
        await preferences.setBool(_onboardingKey(userId), true);
        return true;
      }
    } on FirebaseException catch (_) {
      // Firestore가 아직 준비되지 않은 개발 환경에서는 기기 캐시를 사용합니다.
    } on TimeoutException catch (_) {
      // Firestore가 아직 준비되지 않은 개발 환경에서는 기기 캐시를 사용합니다.
    }
    return false;
  }

  Future<void> markOnboardingCompleted(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingKey(userId), true);
    try {
      await _firestore.collection('users').doc(userId).set({
        'onboardingCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
    } on FirebaseException catch (_) {
      // Firestore 활성화 전에도 프로토타입 흐름은 유지합니다.
    } on TimeoutException catch (_) {
      // Firestore 활성화 전에도 프로토타입 흐름은 유지합니다.
    }
  }

  Future<void> saveOnboardingPreferences({
    required String userId,
    required int height,
    required int weight,
    required String gender,
    required bool useBasicWardrobe,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setInt(_heightKey(userId), height),
      preferences.setInt(_weightKey(userId), weight),
      preferences.setString(_genderKey(userId), gender),
      preferences.setBool(_basicWardrobeKey(userId), useBasicWardrobe),
    ]);
    try {
      await _firestore.collection('users').doc(userId).set({
        'height': height,
        'weight': weight,
        'gender': gender,
        'useBasicWardrobe': useBasicWardrobe,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 3));
    } on FirebaseException catch (_) {
      // Firestore 활성화 전에도 로컬 온보딩 설정을 유지합니다.
    } on TimeoutException catch (_) {
      // Firestore 활성화 전에도 로컬 온보딩 설정을 유지합니다.
    }
  }

  Future<OnboardingPreferences?> loadOnboardingPreferences(
      String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final localHeight = preferences.getInt(_heightKey(userId));
    final localWeight = preferences.getInt(_weightKey(userId));
    final localGender = preferences.getString(_genderKey(userId));
    final localBasic = preferences.getBool(_basicWardrobeKey(userId));
    if (localHeight != null && localWeight != null && localBasic != null) {
      return OnboardingPreferences(
        height: localHeight,
        weight: localWeight,
        gender: localGender == '남' ? '남' : '여',
        useBasicWardrobe: localBasic,
      );
    }
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 3));
      final data = snapshot.data();
      final height = data?['height'];
      final weight = data?['weight'];
      final gender = data?['gender'];
      final useBasicWardrobe = data?['useBasicWardrobe'];
      if (height is int && weight is int && useBasicWardrobe is bool) {
        await Future.wait([
          preferences.setInt(_heightKey(userId), height),
          preferences.setInt(_weightKey(userId), weight),
          preferences.setString(_genderKey(userId), gender == '남' ? '남' : '여'),
          preferences.setBool(_basicWardrobeKey(userId), useBasicWardrobe),
        ]);
        return OnboardingPreferences(
          height: height,
          weight: weight,
          gender: gender == '남' ? '남' : '여',
          useBasicWardrobe: useBasicWardrobe,
        );
      }
    } on FirebaseException catch (_) {
      // 원격 설정을 읽을 수 없으면 기본 온보딩 설정을 사용합니다.
    } on TimeoutException catch (_) {
      // 원격 설정을 읽을 수 없으면 기본 온보딩 설정을 사용합니다.
    }
    return null;
  }

  Future<void> deleteProfile(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_onboardingKey(userId));
    await preferences.remove(_consentKey(userId));
    await preferences.remove(_heightKey(userId));
    await preferences.remove(_weightKey(userId));
    await preferences.remove(_genderKey(userId));
    await preferences.remove(_basicWardrobeKey(userId));
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .delete()
          .timeout(const Duration(seconds: 3));
    } on FirebaseException catch (_) {
      // 계정 삭제는 인증 계정 삭제를 우선하며, 원격 데이터 정리는 백엔드에서도 수행합니다.
    } on TimeoutException catch (_) {
      // 계정 삭제는 인증 계정 삭제를 우선하며, 원격 데이터 정리는 백엔드에서도 수행합니다.
    }
  }
}

class OnboardingPreferences {
  const OnboardingPreferences({
    required this.height,
    required this.weight,
    required this.gender,
    required this.useBasicWardrobe,
  });

  final int height;
  final int weight;
  final String gender;
  final bool useBasicWardrobe;
}
