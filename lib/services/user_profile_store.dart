import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileStore {
  UserProfileStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String _onboardingKey(String userId) =>
      'chakchak.onboarding.completed.$userId';

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

  Future<void> deleteProfile(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_onboardingKey(userId));
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
