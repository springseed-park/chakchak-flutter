import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'design_system.dart';
import 'services/app_auth.dart';
import 'services/backend_service.dart';
import 'services/google_calendar_service.dart';
import 'services/location_weather_service.dart';
import 'services/user_profile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 8));
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(const ChakchakApp());
}

class ChakchakApp extends StatelessWidget {
  const ChakchakApp({super.key, this.auth});

  final AppAuth? auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '착착 CHAKCHAK',
      debugShowCheckedModeBanner: false,
      theme: ChakchakTheme.light(),
      home: AppFlow(auth: auth),
    );
  }
}

class AppColors {
  static const ink = ChakchakColors.textPrimary;
  static const paper = ChakchakColors.canvas;
  static const mist = Color(0xFFF2F5F4);
  static const mint = ChakchakColors.brandPrimary;
  static const mintDark = ChakchakColors.brandPrimary;
  static const coral = Color(0xFFFF9775);
  static const sky = Color(0xFF9BC7ED);
  static const lavender = Color(0xFFCBBDEE);
  static const sand = Color(0xFFF3D393);
  static const line = ChakchakColors.borderSubtle;
  static const muted = ChakchakColors.textDisabled;
  static const onDarkMuted = Color(0xE6FFFFFF);
}

class AppA11y {
  static const touchTarget = 48.0;
  static const controlHeight = 48.0;
  static const iconSize = 24.0;
  static const compactIconSize = 20.0;
  static const captionSize = 12.0;
  static const metadataSize = 13.0;
}

class AppRadius {
  static const card = ChakchakRadii.card;
  static const control = ChakchakRadii.control;
  static const media = ChakchakRadii.control;
  static const medium = ChakchakRadii.medium;
  static const full = ChakchakRadii.full;
}

String formatKoreanDate(DateTime date) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
}

String formatKoreanHeroDate(DateTime date) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 · ${weekdays[date.weekday - 1]}';
}

class SavedOutfitRecord {
  const SavedOutfitRecord({
    required this.date,
    required this.title,
    required this.description,
    required this.garmentNames,
  });

  final DateTime date;
  final String title;
  final String description;
  final List<String> garmentNames;

  Map<String, dynamic> toJson() => {
        'date': DateUtils.dateOnly(date).toIso8601String(),
        'title': title,
        'description': description,
        'garmentNames': garmentNames,
      };

  factory SavedOutfitRecord.fromJson(Map<String, dynamic> json) {
    final rawNames = json['garmentNames'];
    return SavedOutfitRecord(
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      garmentNames: rawNames is List
          ? rawNames.whereType<String>().toList(growable: false)
          : const [],
    );
  }
}

List<SavedOutfitRecord> demoLastYearOutfits([DateTime? anchorDate]) {
  final anchor = DateUtils.dateOnly(anchorDate ?? DateTime.now());
  final year = anchor.year - 1;
  return [
    SavedOutfitRecord(
      date: DateTime(year, anchor.month, anchor.day - 9),
      title: '화이트 반팔티와 라이트 블루 데님',
      description: '맑고 더운 날 가볍게 입었던 기본 조합이에요.',
      garmentNames: const [
        '화이트 베이직 반팔티',
        '라이트 블루 스트레이트 데님',
        '화이트 로우탑 스니커즈',
      ],
    ),
    SavedOutfitRecord(
      date: DateTime(year, anchor.month, anchor.day - 3),
      title: '블랙 반팔티와 베이지 버뮤다',
      description: '주말 외출에 시원하고 편하게 입었던 코디예요.',
      garmentNames: const [
        '블랙 베이직 반팔티',
        '베이지 버뮤다 팬츠',
        '화이트 러닝화',
      ],
    ),
    SavedOutfitRecord(
      date: DateTime(year, anchor.month, anchor.day + 2),
      title: '화이트 나시와 블랙 쇼츠',
      description: '기온이 높았던 날 선택한 가벼운 조합이에요.',
      garmentNames: const [
        '화이트 베이직 나시티',
        '블랙 베이직 쇼츠',
        '블랙 하이탑 스니커즈',
      ],
    ),
    SavedOutfitRecord(
      date: DateTime(year, anchor.month, anchor.day + 7),
      title: '화이트 셔츠와 블랙 슬랙스',
      description: '조금 선선한 미팅 날 단정하게 입었던 기록이에요.',
      garmentNames: const [
        '화이트 베이직 셔츠',
        '블랙 와이드 슬랙스',
        '블랙 클래식 로퍼',
      ],
    ),
  ];
}

final List<String> appCategories = [
  '상의',
  '하의',
  '아우터',
  '원피스',
  '신발',
  '가방',
  '액세서리'
];
const List<String> koreaRegions = [
  '서울',
  '인천',
  '대전',
  '대구',
  '부산',
  '광주',
  '울산',
  '강원',
  '경기',
  '충남',
  '충북',
  '전남',
  '전북',
  '세종',
  '경남',
  '경북',
  '제주'
];
const List<String> landingCharacterAssets = [
  'assets/characters/chakchak-date.png',
  'assets/characters/chakchak-rain.png',
  'assets/characters/chakchak-business.png',
  'assets/characters/chakchak-study.png',
  'assets/characters/chakchak-travel.png',
  'assets/characters/chakchak-exercise.png',
  'assets/characters/chakchak-picnic.png',
];

class AppFlow extends StatefulWidget {
  const AppFlow({super.key, this.auth});

  final AppAuth? auth;

  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  AppStage _stage = AppStage.landing;
  OnboardingResult? _onboardingResult;
  bool _isRestoringSession = true;
  bool _isDeletingAccount = false;
  late final AppAuth _auth;
  UserProfileStore? _profileStore;
  BackendService? _backend;
  final GoogleCalendarService _calendarService = GoogleCalendarService();

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ??
        (Firebase.apps.isEmpty
            ? const UnavailableAppAuth()
            : FirebaseAppAuth());
    if (Firebase.apps.isNotEmpty) {
      _profileStore = UserProfileStore();
      _backend = BackendService();
    }
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      if (mounted) setState(() => _isRestoringSession = false);
      return;
    }
    final completed = await (_profileStore?.hasCompletedOnboarding(userId) ??
        Future<bool>.value(false));
    final preferences = completed
        ? await _profileStore?.loadOnboardingPreferences(userId)
        : null;
    final consentAccepted = completed ||
        await (_profileStore?.hasAcceptedTerms(userId) ??
            Future<bool>.value(false));
    if (!consentAccepted) {
      await _auth.signOut();
    }
    if (!mounted) return;
    setState(() {
      _onboardingResult = preferences == null
          ? null
          : OnboardingResult(
              height: preferences.height,
              weight: preferences.weight,
              gender: preferences.gender,
              useBasicWardrobe: preferences.useBasicWardrobe,
            );
      _stage = !consentAccepted
          ? AppStage.landing
          : completed
              ? AppStage.home
              : AppStage.onboarding;
      _isRestoringSession = false;
    });
  }

  void _goTo(AppStage stage) => setState(() => _stage = stage);

  Future<void> _signedIn(AppSignInResult result) async {
    // Firebase가 신규 계정이라고 확인한 경우에는 Firestore의 온보딩 상태를
    // 다시 조회할 필요가 없습니다. 중복 조회 동안 이전 화면이 노출되지 않도록
    // 바로 첫 온보딩 단계로 전환합니다.
    if (result.isNewUser) {
      if (!mounted) return;
      setState(() {
        _onboardingResult = null;
        _stage = AppStage.onboarding;
      });
      return;
    }
    final completed =
        await (_profileStore?.hasCompletedOnboarding(result.userId) ??
            Future<bool>.value(false));
    final preferences = completed
        ? await _profileStore?.loadOnboardingPreferences(result.userId)
        : null;
    if (!mounted) return;
    setState(() {
      _onboardingResult = preferences == null
          ? null
          : OnboardingResult(
              height: preferences.height,
              weight: preferences.weight,
              gender: preferences.gender,
              useBasicWardrobe: preferences.useBasicWardrobe,
            );
      _stage = completed ? AppStage.home : AppStage.onboarding;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) _goTo(AppStage.landing);
  }

  Future<void> _deleteAccount() async {
    final userId = _auth.currentUserId;
    if (mounted) {
      setState(() => _isDeletingAccount = true);
    }
    try {
      try {
        await _backend?.deleteMyData();
      } catch (_) {
        // Functions 미배포 개발 환경에서는 로컬 및 인증 계정 삭제를 계속 진행합니다.
      }
      if (userId != null) await _profileStore?.deleteProfile(userId);
      await _auth.deleteCurrentUser();
    } finally {
      try {
        // 계정 삭제 성공 여부와 관계없이 탈퇴 흐름이 끝나면 인증 세션을
        // 명시적으로 종료해 뒤로가기로 홈에 다시 진입하지 못하게 합니다.
        await _auth.signOut();
      } catch (_) {
        // 화면과 앱의 로그인 상태 초기화는 계속 진행합니다.
      }
      if (!mounted) return;
      setState(() {
        _onboardingResult = null;
        _isRestoringSession = false;
        _isDeletingAccount = false;
        _stage = AppStage.landing;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    late final Widget screen;
    late final String screenKey;
    if (_isDeletingAccount) {
      screenKey = 'deleting-account';
      screen = const _AccountDeletionProgressScreen();
    } else if (_isRestoringSession) {
      screenKey = 'restoring';
      screen = const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      screenKey = _stage.name;
      screen = switch (_stage) {
        AppStage.landing => LandingScreen(
            auth: _auth,
            profileStore: _profileStore,
            onSignedIn: _signedIn,
          ),
        AppStage.onboarding => OnboardingScreen(onDone: (result) {
            final userId = _auth.currentUserId;
            if (userId != null) {
              unawaited(Future.wait([
                _profileStore?.markOnboardingCompleted(userId) ??
                    Future<void>.value(),
                _profileStore?.saveOnboardingPreferences(
                      userId: userId,
                      height: result.height,
                      weight: result.weight,
                      gender: result.gender,
                      useBasicWardrobe: result.useBasicWardrobe,
                    ) ??
                    Future<void>.value(),
              ]));
            }
            setState(() {
              _onboardingResult = result;
              _stage = AppStage.home;
            });
          }),
        AppStage.home => MainShell(
            initialGarments: _onboardingResult == null
                ? null
                : _onboardingResult!.useBasicWardrobe
                    ? starterGarmentsForGender(_onboardingResult!.gender)
                    : const <GarmentItem>[],
            initialHeight: _onboardingResult?.height,
            initialWeight: _onboardingResult?.weight,
            initialGender: _onboardingResult?.gender,
            accountDisplayName: _auth.currentUserDisplayName,
            accountEmail: _auth.currentUserEmail,
            accountPhotoUrl: _auth.currentUserPhotoUrl,
            onLoadGoogleCalendarEvents: (date) async {
              final accessToken = await _auth.authorizeGoogleCalendar();
              return _calendarService.loadEvents(
                accessToken: accessToken,
                date: date,
              );
            },
            onLogout: _logout,
            onDeleteAccount: _deleteAccount),
      };
    }
    return _ResponsivePortfolioShell(screenKey: screenKey, child: screen);
  }
}

class _AccountDeletionProgressScreen extends StatelessWidget {
  const _AccountDeletionProgressScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: ValueKey('account-deletion-progress'),
      backgroundColor: AppColors.paper,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ChakchakColors.brandPrimary,
              ),
            ),
            SizedBox(height: 18),
            Text('탈퇴 처리 중이에요', style: ChakchakTypography.section),
            SizedBox(height: 8),
            Text(
              '계정과 착착 데이터를 안전하게 삭제하고 있어요.',
              textAlign: TextAlign.center,
              style: ChakchakTypography.label,
            ),
          ],
        ),
      ),
    );
  }
}

enum AppStage { landing, onboarding, home }

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    required this.auth,
    required this.profileStore,
    required this.onSignedIn,
  });
  final AppAuth auth;
  final UserProfileStore? profileStore;
  final Future<void> Function(AppSignInResult result) onSignedIn;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _isSigningIn = false;
  bool _isLoginModalOpen = false;
  bool _isConsentModalOpen = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  AppSignInResult? _pendingSignIn;
  String _loginStatus = '';
  late final String _characterAsset;

  @override
  void initState() {
    super.initState();
    _characterAsset =
        landingCharacterAssets[Random().nextInt(landingCharacterAssets.length)];
  }

  Future<void> _signIn(BuildContext presentationContext) async {
    setState(() {
      _isSigningIn = true;
      _loginStatus = 'Google 계정 선택창을 여는 중이에요.';
    });
    try {
      final result = await widget.auth.signInWithGoogle();
      if (!mounted) return;
      setState(() {
        _loginStatus = '';
        _isLoginModalOpen = false;
      });
      final onboardingCompleted =
          await (widget.profileStore?.hasCompletedOnboarding(result.userId) ??
              Future<bool>.value(false));
      final consentAccepted = onboardingCompleted ||
          await (widget.profileStore?.hasAcceptedTerms(result.userId) ??
              Future<bool>.value(false));
      if (!consentAccepted) {
        if (!mounted) return;
        setState(() {
          _pendingSignIn = result;
          _termsAccepted = false;
          _privacyAccepted = false;
          _isConsentModalOpen = true;
        });
        return;
      }
      if (mounted) await widget.onSignedIn(result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loginStatus = error.toString());
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _acceptConsent() async {
    final result = _pendingSignIn;
    if (result == null || !_termsAccepted || !_privacyAccepted) return;
    await widget.profileStore?.markTermsAccepted(result.userId);
    if (!mounted) return;
    // 목적 화면이 결정되기 전에 동의 모달을 닫으면 비동기 프로필 조회 동안
    // 랜딩/홈이 잠깐 보인다. 상위 AppFlow가 온보딩 또는 홈으로 교체될 때까지
    // 현재 화면을 유지해 중간 화면 노출을 막습니다.
    await widget.onSignedIn(result);
    if (!mounted) return;
    setState(() {
      _isConsentModalOpen = false;
      _pendingSignIn = null;
    });
  }

  Future<void> _cancelConsent() async {
    await widget.auth.signOut();
    if (!mounted) return;
    setState(() {
      _isConsentModalOpen = false;
      _pendingSignIn = null;
      _termsAccepted = false;
      _privacyAccepted = false;
    });
  }

  Future<void> _showPolicy(
          {required BuildContext presentationContext,
          required String title,
          required String content}) =>
      showModalBottomSheet<void>(
        context: presentationContext,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: AppColors.paper,
        builder: (context) => SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ChakchakTypography.section),
                const SizedBox(height: 12),
                Text(content,
                    style: const TextStyle(
                        fontSize: 12, height: 1.6, color: Color(0xFF63706C))),
                const SizedBox(height: 18),
                OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: const Text('확인')),
              ]),
        )),
      );

  @override
  Widget build(BuildContext context) => Stack(children: [
        _LandingCanvas(
          characterAsset: _characterAsset,
          isSigningIn: _isSigningIn,
          isLoginModalOpen: _isLoginModalOpen,
          loginStatus: _loginStatus,
          onOpenLogin: () => setState(() {
            _loginStatus = '';
            _isLoginModalOpen = true;
          }),
          onCloseLogin: () => setState(() {
            _loginStatus = '';
            _isLoginModalOpen = false;
          }),
          onConfirmLogin: _signIn,
        ),
        if (_isConsentModalOpen)
          Positioned.fill(
            child: _SignupConsentOverlay(
              terms: _termsAccepted,
              privacy: _privacyAccepted,
              onTermsChanged: (value) => setState(() => _termsAccepted = value),
              onPrivacyChanged: (value) =>
                  setState(() => _privacyAccepted = value),
              onOpenTerms: () => _showPolicy(
                presentationContext: context,
                title: '서비스 이용약관',
                content:
                    '착착은 사용자가 등록한 옷, 날씨와 일정 정보를 활용해 코디를 추천합니다. Google 계정으로 가입하며 등록 정보는 코디 추천 제공을 위해 처리됩니다.',
              ),
              onOpenPrivacy: () => _showPolicy(
                presentationContext: context,
                title: '개인정보 처리방침',
                content:
                    'Google 계정의 이름·이메일·프로필 사진과 사용자가 입력한 옷장·일정·선호 정보를 로그인과 개인화 추천 목적으로 처리합니다. 회원 탈퇴 시 착착 데이터를 삭제합니다.',
              ),
              onAccept: _acceptConsent,
              onCancel: _cancelConsent,
            ),
          ),
      ]);
}

class _SignupConsentOverlay extends StatelessWidget {
  const _SignupConsentOverlay({
    required this.terms,
    required this.privacy,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.onAccept,
    required this.onCancel,
  });

  final bool terms;
  final bool privacy;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onPrivacyChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(color: Color(0x80142A25)),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 23, 20, 19),
              decoration: BoxDecoration(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      '착착 가입 약관 동의',
                      style: ChakchakTypography.section,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Center(
                    child: Text(
                      '처음 가입할 때 한 번만 동의하면 됩니다.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 9),
                  _ConsentRow(
                    value: terms,
                    label: '서비스 이용약관',
                    onChanged: onTermsChanged,
                    onOpen: onOpenTerms,
                  ),
                  _ConsentRow(
                    value: privacy,
                    label: '개인정보 처리방침',
                    onChanged: onPrivacyChanged,
                    onOpen: onOpenPrivacy,
                  ),
                  const SizedBox(height: 10),
                  _ExactButton(
                    height: 48,
                    background: AppColors.mint,
                    foreground: Colors.white,
                    radius: 14,
                    enabled: terms && privacy,
                    label: '동의하고 가입하기',
                    onPressed: onAccept,
                  ),
                  const SizedBox(height: 8),
                  _ExactButton(
                    height: 48,
                    background: Colors.white,
                    foreground: AppColors.ink,
                    border: AppColors.line,
                    radius: 13,
                    label: '가입 취소',
                    onPressed: onCancel,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _ExactButton extends StatelessWidget {
  const _ExactButton({
    super.key,
    required this.height,
    required this.background,
    required this.foreground,
    required this.radius,
    required this.label,
    required this.onPressed,
    this.border,
    this.enabled = true,
    this.loading = false,
  });

  final double height;
  final Color background;
  final Color foreground;
  final Color? border;
  final double radius;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: enabled && !loading,
        child: MouseRegion(
          cursor: enabled && !loading
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: enabled && !loading ? onPressed : null,
            child: Container(
              width: double.infinity,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled || loading
                    ? background
                    : ChakchakColors.disabledFill,
                border: Border.all(
                  color: enabled || loading
                      ? (border ?? ChakchakColors.borderSubtle)
                      : ChakchakColors.borderSubtle,
                ),
                borderRadius: BorderRadius.circular(ChakchakRadii.control),
              ),
              child: loading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: ChakchakTypography.bodyStrong
                              .copyWith(color: foreground),
                        ),
                      ],
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      style: ChakchakTypography.bodyStrong.copyWith(
                        color:
                            enabled ? foreground : ChakchakColors.disabledText,
                      ),
                    ),
            ),
          ),
        ),
      );
}

class _ResponsivePortfolioShell extends StatelessWidget {
  const _ResponsivePortfolioShell({
    required this.screenKey,
    required this.child,
  });

  final String screenKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 760) return child;
          return Scaffold(
            backgroundColor: const Color(0xFFEDF0ED),
            body: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(ChakchakSpacing.section),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          key: const ValueKey('portfolio-phone-frame'),
                          width: 402,
                          height: 874,
                          child: _PortfolioPhoneFrame(
                            child: Navigator(
                              key: ValueKey('portfolio-navigator-$screenKey'),
                              onGenerateRoute: (_) => MaterialPageRoute<void>(
                                builder: (_) => child,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: ChakchakSpacing.sectionLarge),
                        const _PortfolioIntro(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _LandingCanvas extends StatelessWidget {
  const _LandingCanvas({
    required this.characterAsset,
    required this.isSigningIn,
    required this.isLoginModalOpen,
    required this.loginStatus,
    required this.onOpenLogin,
    required this.onCloseLogin,
    required this.onConfirmLogin,
  });

  final String characterAsset;
  final bool isSigningIn;
  final bool isLoginModalOpen;
  final String loginStatus;
  final VoidCallback onOpenLogin;
  final VoidCallback onCloseLogin;
  final ValueChanged<BuildContext> onConfirmLogin;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.paper,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-.5, -.866),
                    end: Alignment(.5, .866),
                    colors: [
                      Color(0xFFEEFBF7),
                      Color(0xFFFDF7EF),
                      Color(0xFFF8DFB5),
                    ],
                    stops: [0, .56, 1],
                  ),
                ),
              ),
            ),
            Positioned(
                right: -85,
                top: 75,
                child: _LandingGlow(
                    color: const Color(0xFFB8EBDF).withValues(alpha: .7),
                    size: 220)),
            Positioned(
                left: -80,
                bottom: 180,
                child: _LandingGlow(
                    color: const Color(0xFFFDE0AE).withValues(alpha: .7),
                    size: 190)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LandingHeader(),
                  const SizedBox(height: 50),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: _FloatingLandingCharacter(
                            characterAsset,
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'MY PERSONAL OUTFIT ASSISTANT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            height: 11 / 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.7,
                            color: Color(0xFF548176),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Text.rich(
                          const TextSpan(children: [
                            TextSpan(text: '내 옷으로,\n'),
                            TextSpan(
                                text: '오늘의 코디가 착착.',
                                style: TextStyle(color: Color(0xFF24826E))),
                          ]),
                          textAlign: TextAlign.center,
                          style: ChakchakTypography.hero,
                        ),
                        const SizedBox(height: 17),
                        const Text(
                          '날씨와 오늘의 일정을 보고\n코디 메이트가 함께 골라줘요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5E6C68),
                          ),
                        ),
                        const Spacer(),
                        const LandingPreview(),
                        const SizedBox(height: ChakchakSpacing.md),
                        _LandingGoogleButton(
                          isSigningIn: isSigningIn,
                          onPressed: onOpenLogin,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoginModalOpen)
              _LandingLoginOverlay(
                isSigningIn: isSigningIn,
                status: loginStatus,
                onClose: onCloseLogin,
                onConfirm: () => onConfirmLogin(context),
              ),
          ],
        ),
      );
}

class _LandingLoginOverlay extends StatelessWidget {
  const _LandingLoginOverlay({
    required this.isSigningIn,
    required this.status,
    required this.onClose,
    required this.onConfirm,
  });

  final bool isSigningIn;
  final String status;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: ColoredBox(
                  color: const Color(0x80142A25).withValues(alpha: .5 * value),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: -24 * (1 - value),
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(ChakchakRadii.card),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
                          shape: BoxShape.circle,
                        ),
                        child: const GoogleMark(
                          size: 28,
                          markKey: ValueKey('google-popup-brand-mark'),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Google 계정으로\n안전하게 시작할게요',
                        textAlign: TextAlign.center,
                        style:
                            ChakchakTypography.section.copyWith(height: 1.35),
                      ),
                      const SizedBox(height: 9),
                      const Text(
                        'Google에서 이름, 이메일, 프로필 사진만 받아\n착착 계정에 표시합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6E7875),
                        ),
                      ),
                      if (status.isNotEmpty && !isSigningIn) ...[
                        const SizedBox(height: 12),
                        Text(
                          status,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ChakchakTypography.caption.copyWith(
                            color: const Color(0xFFB45142),
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _ExactButton(
                        key: const ValueKey('google-account-select-button'),
                        height: 48,
                        background: AppColors.mint,
                        foreground: Colors.white,
                        radius: 14,
                        enabled: !isSigningIn,
                        loading: isSigningIn,
                        label: isSigningIn
                            ? 'Google 계정 선택창을 여는 중이에요.'
                            : 'Google 계정 선택하기',
                        onPressed: onConfirm,
                      ),
                      const SizedBox(height: 10),
                      _ExactButton(
                        key: const ValueKey('google-login-cancel-button'),
                        height: 48,
                        background: Colors.white,
                        foreground: AppColors.ink,
                        border: AppColors.line,
                        radius: 13,
                        label: '취소',
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader();

  @override
  Widget build(BuildContext context) => Column(children: [
        const SizedBox(
            height: 14,
            child: Row(children: [
              Text('9:41',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Spacer(),
              Text('● ● ●  ▰',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ])),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('착착',
              style: TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 30,
                  height: 1,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 4),
          Text('CHAKCHAK',
              key: const ValueKey('landing-english-logo'),
              style: const TextStyle(
                  fontFamily: 'Paperlogy',
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .9,
                  color: AppColors.ink)),
        ]),
      ]);
}

class _LandingGoogleButton extends StatelessWidget {
  const _LandingGoogleButton(
      {required this.isSigningIn, required this.onPressed});

  final bool isSigningIn;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: LayoutBuilder(
          builder: (context, constraints) => OverflowBox(
            minWidth: constraints.maxWidth + 8,
            maxWidth: constraints.maxWidth + 8,
            minHeight: 48,
            maxHeight: 48,
            child: Semantics(
              button: true,
              enabled: !isSigningIn,
              label: isSigningIn ? 'Google 계정 연결 중...' : 'Google로 시작하기',
              child: MouseRegion(
                cursor: isSigningIn
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                child: GestureDetector(
                  key: const ValueKey('google-start-button'),
                  onTap: isSigningIn ? null : onPressed,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          isSigningIn ? const Color(0xBFFFFFFF) : Colors.white,
                      border: Border.all(color: ChakchakColors.borderDefault),
                      borderRadius:
                          BorderRadius.circular(ChakchakRadii.control),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSigningIn)
                          const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ink,
                            ),
                          )
                        else
                          const GoogleMark(),
                        const SizedBox(width: 8),
                        Text(
                          isSigningIn ? 'Google 계정 연결 중...' : 'Google로 시작하기',
                          style: ChakchakTypography.bodyStrong,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _FloatingLandingCharacter extends StatefulWidget {
  const _FloatingLandingCharacter(this.asset);

  final String asset;

  @override
  State<_FloatingLandingCharacter> createState() =>
      _FloatingLandingCharacterState();
}

class _FloatingLandingCharacterState extends State<_FloatingLandingCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _offset = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 248,
        height: 248,
        child: AnimatedBuilder(
          animation: _offset,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, -9 * _offset.value),
            child: child,
          ),
          child: Image.asset(
            widget.asset,
            width: 248,
            height: 248,
            fit: BoxFit.contain,
            semanticLabel: '첫 화면에 무작위로 등장하는 착착 메이트',
          ),
        ),
      );
}

class _LandingGlow extends StatelessWidget {
  const _LandingGlow({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => ImageFiltered(
        key: const ValueKey('landing-glow-blur'),
        imageFilter: ui.ImageFilter.blur(
            sigmaX: 5, sigmaY: 5, tileMode: ui.TileMode.decal),
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      );
}

class _PortfolioPhoneFrame extends StatelessWidget {
  const _PortfolioPhoneFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: 390,
        height: 844,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(46),
          boxShadow: const [
            BoxShadow(
                color: Color(0x361D302A), blurRadius: 90, offset: Offset(0, 34))
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(37), child: child),
      );
}

class _PortfolioIntro extends StatelessWidget {
  const _PortfolioIntro();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 290,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHAKCHAK PORTFOLIO PROTOTYPE',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Color(0xFF4B766C))),
            SizedBox(height: 10),
            Text('내 옷장 × 오늘 날씨 ×\n오늘 일정',
                style: TextStyle(
                    fontFamily: 'NanumMyeongjo',
                    fontSize: 30,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    letterSpacing: -1.5)),
            SizedBox(height: 10),
            Text('정적인 시안이 아니라 클릭하고 대화할 수 있는 로컬 프로토타입입니다.',
                style: TextStyle(
                    fontSize: 13, height: 1.6, color: Color(0xFF6D7774))),
          ],
        ),
      );
}

class LandingPreview extends StatefulWidget {
  const LandingPreview({super.key});

  @override
  State<LandingPreview> createState() => _LandingPreviewState();
}

class _LandingPreviewState extends State<LandingPreview> {
  final PageController _controller = PageController(initialPage: 3000);
  Timer? _timer;
  int _page = 0;
  int _physicalPage = 3000;

  static const _examples = [
    (title: '28° · 오후 외부 미팅', outfit: '린넨 셔츠 + 블랙 슬랙스 어때요?'),
    (title: '19° · 저녁 전시 관람', outfit: '방수 재킷 + 스트레이트 데님이 좋아요.'),
    (title: '12° · 아침 출근', outfit: '가벼운 니트 + 트렌치코트를 챙겨요.'),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(_physicalPage + 1,
          duration: const Duration(milliseconds: 550),
          curve: const Cubic(.22, .75, .25, 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 76,
        child: PageView.builder(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (value) => setState(() {
            _physicalPage = value;
            _page = value % _examples.length;
          }),
          itemBuilder: (context, index) {
            final example = _examples[index % _examples.length];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: const Color(0x99FFFFFF),
                  border: Border.all(color: const Color(0xC7FFFFFF)),
                  borderRadius: BorderRadius.circular(ChakchakRadii.control)),
              child: Row(children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    index % _examples.length == 0
                        ? Icons.wb_sunny_outlined
                        : index % _examples.length == 1
                            ? Icons.umbrella_outlined
                            : Icons.cloud_outlined,
                    size: 32,
                    color: ChakchakColors.textPrimary,
                  ),
                ),
                const SizedBox(width: ChakchakSpacing.iconGap),
                Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(example.title,
                          style: ChakchakTypography.labelStrong),
                      const SizedBox(height: ChakchakSpacing.xs),
                      Text(example.outfit,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1,
                              color: Color(0xFF848E89))),
                    ])),
              ]),
            );
          },
        ),
      ),
      SizedBox(
        height: 14,
        child: Row(
          key: const ValueKey('landing-indicator-row'),
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < _examples.length; index++) ...[
              if (index > 0) const SizedBox(width: 5),
              Semantics(
                button: true,
                selected: index == _page,
                label: '${index + 1}번째 코디 예시 보기',
                child: GestureDetector(
                  onTap: () {
                    var target = _physicalPage -
                        (_physicalPage % _examples.length) +
                        index;
                    if (target < _physicalPage) target += _examples.length;
                    _controller.animateToPage(target,
                        duration: const Duration(milliseconds: 550),
                        curve: const Cubic(.22, .75, .25, 1));
                    _startTimer();
                  },
                  child: SizedBox(
                    width: index == _page ? 16 : 5,
                    height: 14,
                    child: Center(
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: index == _page ? 16 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                              color: index == _page
                                  ? AppColors.ink
                                  : const Color(0x66253A34),
                              borderRadius: BorderRadius.circular(99))),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ]);
  }
}

class OnboardingResult {
  const OnboardingResult({
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final ValueChanged<OnboardingResult> onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  String selectedCity = '서울';
  String? detectedLocationLabel;
  String? locationError;
  bool locating = false;
  final Set<String> styles = {'미니멀'};
  final LocationWeatherService _locationService = LocationWeatherService();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  String gender = '여';
  bool useBasicWardrobe = true;
  String? bodyProfileError;

  @override
  void dispose() {
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  void _next() {
    if (step == 2) {
      final height = int.tryParse(heightController.text.trim());
      final weight = int.tryParse(weightController.text.trim());
      if (height == null ||
          weight == null ||
          height < 120 ||
          height > 220 ||
          weight < 30 ||
          weight > 200) {
        setState(() {
          bodyProfileError = '키 120~220cm, 몸무게 30~200kg 범위로 입력해주세요.';
        });
        return;
      }
      widget.onDone(OnboardingResult(
        height: height,
        weight: weight,
        gender: gender,
        useBasicWardrobe: useBasicWardrobe,
      ));
    } else {
      setState(() => step += 1);
    }
  }

  Future<void> _useCurrentLocation() async {
    if (locating) return;
    setState(() {
      locating = true;
      locationError = null;
    });
    try {
      final result = await _locationService.locateCurrentRegion();
      if (!mounted) return;
      setState(() {
        if (koreaRegions.contains(result.region)) {
          selectedCity = result.region;
        }
        detectedLocationLabel = result.locationLabel;
      });
    } catch (error) {
      if (!mounted) return;
      final detail = error.toString().toLowerCase();
      setState(() {
        locationError = detail.contains('denied') || detail.contains('권한')
            ? '위치 권한이 꺼져 있어요. 지역을 직접 선택해주세요.'
            : '현재 위치를 찾지 못했어요. 잠시 후 다시 시도해주세요.';
      });
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardingCity(
        city: selectedCity,
        locationLabel: detectedLocationLabel,
        locationError: locationError,
        locating: locating,
        onUseCurrentLocation: _useCurrentLocation,
        onCityChanged: (value) => setState(() {
          selectedCity = value;
          detectedLocationLabel = null;
          locationError = null;
        }),
      ),
      _OnboardingStyle(
        selected: styles,
        onToggle: (value) => setState(() =>
            styles.contains(value) ? styles.remove(value) : styles.add(value)),
      ),
      _OnboardingBodyAndCloset(
        heightController: heightController,
        weightController: weightController,
        gender: gender,
        useBasicWardrobe: useBasicWardrobe,
        errorText: bodyProfileError,
        onWardrobeChanged: (value) => setState(() {
          useBasicWardrobe = value;
          bodyProfileError = null;
        }),
        onGenderChanged: (value) => setState(() {
          gender = value;
          bodyProfileError = null;
        }),
        onBodyChanged: () {
          if (bodyProfileError != null) {
            setState(() => bodyProfileError = null);
          }
        },
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  for (var index = 0; index < 3; index++) ...[
                    Expanded(
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 0),
                            height: 7,
                            decoration: BoxDecoration(
                                color: index <= step
                                    ? AppColors.mintDark
                                    : AppColors.line,
                                borderRadius: BorderRadius.circular(8)))),
                    if (index < 2) const SizedBox(width: 5),
                  ],
                ]),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: pages[step],
                  ),
                ),
                _ExactButton(
                  height: 48,
                  background: AppColors.mint,
                  foreground: Colors.white,
                  radius: 14,
                  label: step == 2 ? '착착 시작하기' : '다음',
                  onPressed: _next,
                ),
              ],
            ),
          ),
          const Positioned(
            left: 26,
            right: 26,
            top: 10,
            child: _PhoneTopBar(),
          ),
        ],
      ),
    );
  }
}

class _PhoneTopBar extends StatelessWidget {
  const _PhoneTopBar({this.color = AppColors.ink});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 14,
        child: Row(
          children: [
            Text('9:41',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('● ● ●  ▰',
                style: TextStyle(
                    color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _OnboardingCharacter extends StatelessWidget {
  const _OnboardingCharacter(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 150,
        height: 124,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 150,
          maxWidth: 150,
          minHeight: 150,
          maxHeight: 150,
          child: Transform.translate(
            offset: const Offset(-18, -18),
            child: Image.asset(asset,
                width: 150, height: 150, fit: BoxFit.contain),
          ),
        ),
      );
}

class _OnboardingHeading extends StatelessWidget {
  const _OnboardingHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: ChakchakTypography.hero,
      );
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: ChakchakTypography.bodyLight.copyWith(
          color: ChakchakColors.textStrongSecondary,
        ),
      );
}

class _OnboardingChip extends StatelessWidget {
  const _OnboardingChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.grid = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool grid;

  @override
  Widget build(BuildContext context) => ChakchakRoundChip(
        label: label,
        selected: selected,
        onTap: onTap,
      );
}

class _OnboardingCity extends StatelessWidget {
  const _OnboardingCity({
    required this.city,
    required this.locationLabel,
    required this.locationError,
    required this.locating,
    required this.onUseCurrentLocation,
    required this.onCityChanged,
  });
  final String city;
  final String? locationLabel;
  final String? locationError;
  final bool locating;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<String> onCityChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 281.890625,
      child: Column(
        key: const ValueKey('city'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OnboardingCharacter('assets/characters/chakchak-travel.png'),
          const SizedBox(height: 24),
          const _OnboardingHeading('오늘의 날씨는\n어디를 기준으로 볼까요?'),
          const SizedBox(height: 10),
          const _OnboardingCopy('내 위치를 찾거나 지역을 직접 고를 수 있어요.'),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: locating ? null : onUseCurrentLocation,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF9F5),
                border: Border.all(color: const Color(0xFFB9E2D5)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (locating)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    )
                  else
                    SvgPicture.asset('assets/icons/map.svg',
                        width: 24, height: 24),
                  const SizedBox(width: 8),
                  Text(
                    locating ? '현재 위치 찾는 중...' : '내 위치로 찾기',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (locationLabel != null || locationError != null) ...[
            const SizedBox(height: 8),
            Text(
              locationError ?? '현재 위치 · $locationLabel',
              style: TextStyle(
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: locationError == null
                    ? AppColors.mintDark
                    : const Color(0xFFB45142),
              ),
            ),
            const SizedBox(height: 8),
          ] else
            const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 33.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: koreaRegions.length,
            itemBuilder: (context, index) {
              final name = koreaRegions[index];
              return _OnboardingChip(
                label: name,
                selected: city == name,
                grid: true,
                onTap: () => onCityChanged(name),
              );
            },
          ),
        ],
      ));
}

class _OnboardingStyle extends StatelessWidget {
  const _OnboardingStyle({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 324,
      child: Column(
        key: const ValueKey('style'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OnboardingCharacter('assets/characters/chakchak-date.png'),
          const SizedBox(height: 24),
          const _OnboardingHeading('평소 좋아하는 스타일을\n알려주세요.'),
          const SizedBox(height: 10),
          const _OnboardingCopy('여러 개를 골라도 괜찮아요. 나중에 바꿀 수 있어요.'),
          const SizedBox(height: 26),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['미니멀', '캐주얼', '페미닌', '모던', '스트릿', '클래식']
                .map((name) => _OnboardingChip(
                      label: name,
                      selected: selected.contains(name),
                      onTap: () => onToggle(name),
                    ))
                .toList(),
          ),
        ],
      ));
}

class _OnboardingBodyAndCloset extends StatelessWidget {
  const _OnboardingBodyAndCloset({
    required this.heightController,
    required this.weightController,
    required this.gender,
    required this.useBasicWardrobe,
    required this.errorText,
    required this.onWardrobeChanged,
    required this.onGenderChanged,
    required this.onBodyChanged,
  });

  final TextEditingController heightController;
  final TextEditingController weightController;
  final String gender;
  final bool useBasicWardrobe;
  final String? errorText;
  final ValueChanged<bool> onWardrobeChanged;
  final ValueChanged<String> onGenderChanged;
  final VoidCallback onBodyChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 324,
      child: Column(
        key: const ValueKey('closet'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _OnboardingCharacter('assets/characters/chakchak-study.png'),
          const SizedBox(height: 14),
          const _OnboardingHeading('내 몸과 옷장 준비를\n마지막으로 알려주세요.'),
          const SizedBox(height: 7),
          const _OnboardingCopy('입력한 정보는 내게 맞는 핏을 추천할 때만 사용해요.'),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(
              child: _OnboardingNumberField(
                key: const ValueKey('onboarding-height'),
                label: '키',
                unit: 'cm',
                controller: heightController,
                onChanged: onBodyChanged,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _OnboardingNumberField(
                key: const ValueKey('onboarding-weight'),
                label: '몸무게',
                unit: 'kg',
                controller: weightController,
                onChanged: onBodyChanged,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            for (final value in ['남', '여']) ...[
              Expanded(
                child: _OnboardingGenderChoice(
                  value: value,
                  selected: gender == value,
                  onTap: () => onGenderChanged(value),
                ),
              ),
              if (value == '남') const SizedBox(width: 9),
            ],
          ]),
          if (errorText != null) ...[
            const SizedBox(height: 5),
            Text(
              errorText!,
              style: const TextStyle(
                fontSize: 9.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45142),
              ),
            ),
          ],
          const SizedBox(height: 13),
          const Text(
            '내 옷장은 어떻게 시작할까요?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 7),
          _OnboardingWardrobeChoice(
            selected: useBasicWardrobe,
            title: '베이직 아이템으로 채우기',
            description: '블랙·화이트·데님·베이지 기본템으로 바로 시작해요.',
            onTap: () => onWardrobeChanged(true),
            showPreview: true,
          ),
          const SizedBox(height: 7),
          _OnboardingWardrobeChoice(
            selected: !useBasicWardrobe,
            title: '내가 하나하나 채우기',
            description: '빈 옷장에서 내 옷을 직접 등록할게요.',
            onTap: () => onWardrobeChanged(false),
          ),
        ],
      ));
}

class _OnboardingGenderChoice extends StatelessWidget {
  const _OnboardingGenderChoice({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: ValueKey('onboarding-gender-$value'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.mintDark : Colors.white,
            border: Border.all(
              color: selected ? AppColors.mintDark : AppColors.line,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class _OnboardingNumberField extends StatelessWidget {
  const _OnboardingNumberField({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => onChanged(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: label,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9AA4A0),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF77817E),
            ),
          ),
        ]),
      );
}

class _OnboardingWardrobeChoice extends StatelessWidget {
  const _OnboardingWardrobeChoice({
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
    this.showPreview = false,
  });

  final bool selected;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool showPreview;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEDF9F5) : Colors.white,
            border: Border.all(
              color: selected ? AppColors.mintDark : AppColors.line,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.mintDark : Colors.white,
                border: Border.all(
                  color: selected ? AppColors.mintDark : AppColors.line,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      )),
                  const SizedBox(height: 2),
                  Text(description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF6D7774),
                      )),
                ],
              ),
            ),
            if (showPreview) ...[
              const SizedBox(width: 5),
              SizedBox(
                width: 62,
                height: 38,
                child: Stack(
                  children: [
                    for (var index = 0; index < 3; index++)
                      Positioned(
                        left: index * 17,
                        child: Container(
                          width: 30,
                          height: 38,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: starterBasicGarments[index].tone,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: ColorizedGarmentAsset(
                            assetPath: starterBasicGarments[index].assetPath!,
                            color: starterBasicGarments[index].tintColor!,
                            semanticLabel: starterBasicGarments[index].name,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ]),
        ),
      );
}

class MainShell extends StatefulWidget {
  const MainShell(
      {super.key,
      required this.onLogout,
      required this.onDeleteAccount,
      this.initialGarments,
      this.initialHeight,
      this.initialWeight,
      this.initialGender,
      this.initialIndex = 0,
      this.accountDisplayName,
      this.accountEmail,
      this.accountPhotoUrl,
      this.onLoadGoogleCalendarEvents});
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final List<GarmentItem>? initialGarments;
  final int? initialHeight;
  final int? initialWeight;
  final String? initialGender;
  final int initialIndex;
  final String? accountDisplayName;
  final String? accountEmail;
  final String? accountPhotoUrl;
  final Future<List<GoogleCalendarEvent>> Function(DateTime date)?
      onLoadGoogleCalendarEvents;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _savedOutfitsStorageKey = 'chakchak_saved_outfits_v1';
  late int index;
  bool outfitSaved = false;
  late final List<GarmentItem> garments;
  final List<SavedOutfitRecord> savedOutfits = [];
  List<TodaySchedule> mateSchedules = const [];
  WeatherSnapshot? mateWeather;
  GarmentItem? matePinnedGarment;
  List<GarmentItem>? mateSelectedOutfit;

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
    garments = List.of(widget.initialGarments ?? starterBasicGarments);
    _loadSavedOutfits();
  }

  Future<void> _loadSavedOutfits() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_savedOutfitsStorageKey);
    final decoded = <SavedOutfitRecord>[];
    try {
      if (raw != null && raw.isNotEmpty) {
        decoded.addAll((jsonDecode(raw) as List<dynamic>).whereType<Map>().map(
            (item) =>
                SavedOutfitRecord.fromJson(Map<String, dynamic>.from(item))));
      }
    } catch (_) {
      // 예전 또는 손상된 로컬 기록은 앱 진입을 막지 않는다.
    }
    var seededDemoRecords = false;
    for (final demo in demoLastYearOutfits()) {
      final alreadyExists = decoded.any((record) =>
          DateUtils.isSameDay(record.date, demo.date) &&
          record.title == demo.title);
      if (!alreadyExists) {
        decoded.add(demo);
        seededDemoRecords = true;
      }
    }
    decoded.sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      savedOutfits
        ..clear()
        ..addAll(decoded);
      outfitSaved =
          decoded.any((record) => DateUtils.isSameDay(record.date, today));
    });
    if (seededDemoRecords) await _persistSavedOutfits();
  }

  Future<void> _persistSavedOutfits() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _savedOutfitsStorageKey,
      jsonEncode(savedOutfits.map((record) => record.toJson()).toList()),
    );
  }

  void _toggleOutfitSaved() {
    final willSave = !outfitSaved;
    setState(() {
      outfitSaved = willSave;
      if (!willSave) {
        final today = DateUtils.dateOnly(DateTime.now());
        savedOutfits
            .removeWhere((record) => DateUtils.isSameDay(record.date, today));
      }
    });
    if (!willSave) unawaited(_persistSavedOutfits());
  }

  void _recordSelectedOutfit(_TodayOutfitRecommendation outfit, bool selected) {
    if (!selected) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final items = <GarmentItem>[
      if (outfit.dress != null) outfit.dress! else outfit.top,
      if (outfit.dress == null) outfit.bottom,
      if (outfit.outer != null) outfit.outer!,
      if (outfit.shoes != null) outfit.shoes!,
    ];
    final record = SavedOutfitRecord(
      date: today,
      title: outfit.title,
      description: outfit.description,
      garmentNames: items.map((item) => item.name).toList(growable: false),
    );
    setState(() {
      savedOutfits.removeWhere((item) => DateUtils.isSameDay(item.date, today));
      savedOutfits.insert(0, record);
    });
    unawaited(_persistSavedOutfits());
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
          onAskMate: () => setState(() {
                matePinnedGarment = null;
                index = 2;
              }),
          saved: outfitSaved,
          onSave: _toggleOutfitSaved,
          onOutfitToggle: _recordSelectedOutfit,
          garments: garments,
          savedOutfits: savedOutfits,
          mateSelectedOutfit: mateSelectedOutfit,
          onClearMateOutfit: () => setState(() => mateSelectedOutfit = null),
          onLoadGoogleCalendarEvents: widget.onLoadGoogleCalendarEvents,
          onContextChanged: (schedules, weather) {
            if (!mounted) return;
            setState(() {
              mateSchedules = List.unmodifiable(schedules);
              mateWeather = weather;
            });
          }),
      WardrobeScreen(
        garments: garments,
        outfitSaved: outfitSaved,
        savedOutfits: savedOutfits,
        onAskMate: (item) => setState(() {
          matePinnedGarment = item;
          index = 2;
        }),
        onUpdate: (previous, updated) {
          final garmentIndex = garments.indexOf(previous);
          if (garmentIndex != -1) {
            setState(() => garments[garmentIndex] = updated);
          }
        },
        onAdd: () async {
          final garment = await Navigator.of(context).push<GarmentItem>(
              MaterialPageRoute(builder: (_) => const AddGarmentScreen()));
          if (garment != null) setState(() => garments.insert(0, garment));
        },
      ),
      MateChatScreen(
          key: ValueKey('mate-${matePinnedGarment?.name ?? 'general'}'),
          pinned: matePinnedGarment,
          garments: garments,
          schedules: mateSchedules,
          weather: mateWeather,
          onExit: () => setState(() => index = 0),
          onUseOutfit: (items) => setState(() {
                mateSelectedOutfit = List<GarmentItem>.unmodifiable(items);
                outfitSaved = false;
                index = 0;
              })),
      ProfileScreen(
          accountDisplayName: widget.accountDisplayName,
          accountEmail: widget.accountEmail,
          accountPhotoUrl: widget.accountPhotoUrl,
          initialHeight: widget.initialHeight,
          initialWeight: widget.initialWeight,
          initialGender: widget.initialGender,
          onLogout: widget.onLogout,
          onDeleteAccount: widget.onDeleteAccount),
    ];
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 39, vertical: 7),
          decoration: const BoxDecoration(
            color: ChakchakColors.surface,
            border: Border(
              top: BorderSide(color: ChakchakColors.borderSubtle),
            ),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _BottomNavItem(
                label: '홈',
                asset: 'assets/icons/nav-home.svg',
                selected: index == 0,
                onTap: () => setState(() => index = 0)),
            _BottomNavItem(
                label: '내 옷장',
                asset: 'assets/icons/nav-wardrobe.svg',
                selected: index == 1,
                onTap: () => setState(() => index = 1)),
            _BottomNavItem(
                label: '메이트',
                asset: 'assets/icons/nav-mate.svg',
                selected: index == 2,
                onTap: () => setState(() => index = 2)),
            _BottomNavItem(
                label: '내정보',
                asset: 'assets/icons/nav-my.svg',
                selected: index == 3,
                onTap: () => setState(() => index = 3)),
          ]),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 48,
            height: 52,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NavSvgIcon(asset, selected: selected),
                const SizedBox(height: 2),
                Text(label,
                    maxLines: 1,
                    style: ChakchakTypography.nav.copyWith(
                      color: selected
                          ? ChakchakColors.brandPrimary
                          : ChakchakColors.textNavInactive,
                    )),
              ],
            ),
          ),
        ),
      );
}

class _NavSvgIcon extends StatelessWidget {
  const _NavSvgIcon(this.asset, {this.selected = false});
  final String asset;
  final bool selected;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        asset,
        width: 32,
        height: 32,
        colorFilter: ColorFilter.mode(
          selected
              ? ChakchakColors.brandPrimary
              : ChakchakColors.textNavInactive,
          BlendMode.srcIn,
        ),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key,
      required this.onAskMate,
      required this.saved,
      required this.onSave,
      required this.garments,
      this.savedOutfits = const [],
      this.mateSelectedOutfit,
      this.onClearMateOutfit,
      this.onOutfitToggle,
      this.onContextChanged,
      this.onLoadGoogleCalendarEvents});
  final VoidCallback onAskMate;
  final bool saved;
  final VoidCallback onSave;
  final void Function(_TodayOutfitRecommendation outfit, bool selected)?
      onOutfitToggle;
  final List<GarmentItem> garments;
  final List<SavedOutfitRecord> savedOutfits;
  final List<GarmentItem>? mateSelectedOutfit;
  final VoidCallback? onClearMateOutfit;
  final void Function(List<TodaySchedule> schedules, WeatherSnapshot? weather)?
      onContextChanged;
  final Future<List<GoogleCalendarEvent>> Function(DateTime date)?
      onLoadGoogleCalendarEvents;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _scheduleStorageKey = 'chakchak_schedules_v2';
  static const _weatherRegionStorageKey = 'chakchak_weather_region_v1';
  static const _weatherLocationLabelStorageKey =
      'chakchak_weather_location_label_v1';
  final LocationWeatherService _weatherService = LocationWeatherService();
  WeatherSnapshot? _weather;
  String _locationLabel = '서울 성동구';
  String _selectedRegion = '서울';
  bool _weatherLoading = false;
  int _outfitVariation = 0;
  final List<TodaySchedule> schedules = [
    const TodaySchedule(id: 1, time: '09:00', title: '출근'),
    const TodaySchedule(id: 2, time: '14:00', title: '외부 미팅'),
  ];

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  List<TodaySchedule> get _todaySchedules =>
      schedules.where((item) => item.isOn(_today)).toList(growable: false)
        ..sort((a, b) => a.time.compareTo(b.time));

  @override
  void initState() {
    super.initState();
    _loadSavedWeatherLocation();
    _loadSchedules();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyMateContext());
  }

  Future<void> _loadSavedWeatherLocation() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final region = preferences.getString(_weatherRegionStorageKey);
      final locationLabel =
          preferences.getString(_weatherLocationLabelStorageKey);
      if (!mounted || region == null || !koreaRegions.contains(region)) return;
      setState(() {
        _selectedRegion = region;
        _locationLabel = locationLabel?.trim().isNotEmpty == true
            ? locationLabel!.trim()
            : region;
      });
    } catch (_) {
      // A local-storage failure should not block the home screen.
    }
  }

  Future<void> _persistWeatherLocation() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await Future.wait([
        preferences.setString(_weatherRegionStorageKey, _selectedRegion),
        preferences.setString(_weatherLocationLabelStorageKey, _locationLabel),
      ]);
    } catch (_) {
      // Weather loading should still continue if local persistence fails.
    }
  }

  Future<void> _loadSchedules() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_scheduleStorageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map(
              (item) => TodaySchedule.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (!mounted || decoded.isEmpty) return;
      setState(() {
        schedules
          ..clear()
          ..addAll(decoded);
      });
      _notifyMateContext();
    } catch (_) {
      // Older or malformed local data should not block the home screen.
    }
  }

  Future<void> _persistSchedules() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_scheduleStorageKey,
        jsonEncode(schedules.map((item) => item.toJson()).toList()));
  }

  void _notifyMateContext() =>
      widget.onContextChanged?.call(_todaySchedules, _weather);
  Future<void> _editSchedules() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (context) => ScheduleSheet(
        initialSchedules: schedules,
        onImportGoogleCalendar: widget.onLoadGoogleCalendarEvents == null
            ? null
            : (date) async {
                final events =
                    await widget.onLoadGoogleCalendarEvents!.call(date);
                return events
                    .map((event) => TodaySchedule(
                          id: Object.hash(event.id, event.date, event.time),
                          time: event.time,
                          title: event.title,
                          date: event.date,
                        ))
                    .toList(growable: false);
              },
        onChanged: (updated) {
          if (!mounted) return;
          setState(() {
            schedules
              ..clear()
              ..addAll(updated);
          });
          _persistSchedules();
          _notifyMateContext();
        },
      ),
    );
  }

  void _deleteSchedule(int id) {
    setState(() => schedules.removeWhere((item) => item.id == id));
    _persistSchedules();
    _notifyMateContext();
  }

  Future<void> _refreshWeather() async {
    if (_weatherLoading) return;
    setState(() => _weatherLoading = true);
    LocatedRegion located;
    try {
      located = await _weatherService.locateCurrentRegion();
      if (!mounted) return;
      setState(() {
        _locationLabel = located.locationLabel;
        final detectedRegion = koreaRegions.where(
          (region) => located.locationLabel.startsWith(region),
        );
        if (detectedRegion.isNotEmpty) {
          _selectedRegion = detectedRegion.first;
        }
      });
      await _persistWeatherLocation();
    } catch (error) {
      if (!mounted) return;
      final detail = error.toString().toLowerCase();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          detail.contains('denied') || detail.contains('권한')
              ? '위치 권한을 허용한 뒤 다시 시도해주세요.'
              : '현재 위치를 찾지 못했어요. 지역을 직접 선택해주세요.',
        ),
      ));
      setState(() => _weatherLoading = false);
      return;
    }

    try {
      final result = await _weatherService.loadWeatherForLocatedRegion(located);
      if (!mounted) return;
      setState(() => _weather = result.weather);
      _notifyMateContext();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${result.weather.sourceLabel}를 새로 불러왔어요.'),
        duration: const Duration(seconds: 1),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('위치는 찾았지만 기상청 날씨 연결에 실패했어요.'),
      ));
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  Future<void> _pickWeatherRegion() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      barrierColor: const Color(0x66192420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _WeatherRegionSheet(
        selectedRegion: _selectedRegion,
      ),
    );
    if (result == null || !mounted) return;
    if (result == _WeatherRegionSheet.currentLocationValue) {
      await _refreshWeather();
      return;
    }
    setState(() {
      _weatherLoading = true;
      _selectedRegion = result;
      _locationLabel = result;
    });
    await _persistWeatherLocation();
    try {
      final locatedWeather = await _weatherService.loadWeatherForRegion(result);
      if (!mounted) return;
      setState(() {
        _weather = locatedWeather.weather;
        _locationLabel = locatedWeather.locationLabel;
      });
      await _persistWeatherLocation();
      _notifyMateContext();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 지역의 날씨를 불러오지 못했어요.')),
      );
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: WeatherHero(
              schedules: _todaySchedules,
              weather: _weather,
              locationLabel: _locationLabel,
              loading: _weatherLoading,
              onRefresh: _refreshWeather,
              onLocationTap: _pickWeatherRegion,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              _ScheduleCard(
                  schedules: _todaySchedules,
                  onAdd: _editSchedules,
                  onDelete: _deleteSchedule),
              const SizedBox(height: 36),
              OutfitCard(
                  saved: widget.saved,
                  onSave: widget.onSave,
                  onOutfitToggle: widget.onOutfitToggle,
                  onAskMate: widget.onAskMate,
                  garments: widget.garments,
                  weather: _weather,
                  mateSelectedOutfit: widget.mateSelectedOutfit,
                  variationIndex: _outfitVariation,
                  onRefresh: () {
                    widget.onClearMateOutfit?.call();
                    if (widget.saved) widget.onSave();
                    setState(() => _outfitVariation += 1);
                  },
                  scheduleContext: _todaySchedules
                      .map((item) => '${item.time} ${item.title}')
                      .join(', ')),
              const SizedBox(height: 38),
              SectionTitle(
                title: '착착의 발견',
              ),
              const SizedBox(height: 16),
              ReDiscoveryRow(
                  garments: widget.garments, records: widget.savedOutfits),
            ])),
          ),
        ],
      );
}

class _WeatherRegionSheet extends StatelessWidget {
  const _WeatherRegionSheet({required this.selectedRegion});

  static const currentLocationValue = '__current_location__';

  final String selectedRegion;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '날씨 지역',
                          style: ChakchakTypography.section,
                        ),
                        SizedBox(height: 6),
                        Text(
                          '오늘의 날씨와 체감온도를 확인할 지역을 선택하세요.',
                          style: TextStyle(
                            color: Color(0xFF6D7774),
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F3F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '×',
                        style: TextStyle(
                          color: Color(0xFF76817D),
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: '내 위치로 날씨 지역 찾기',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(currentLocationValue),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECF8F4),
                      border: Border.all(color: const Color(0xFFAFE3D6)),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/map.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            AppColors.ink,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          '내 위치로 찾기',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 7.0;
                  final chipWidth = (constraints.maxWidth - spacing * 4) / 5;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: 8,
                    children: koreaRegions.map((region) {
                      final selected = region == selectedRegion;
                      return GestureDetector(
                        onTap: () => Navigator.of(context).pop(region),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: chipWidth,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.mintDark : Colors.white,
                            border: Border.all(
                              color: selected
                                  ? AppColors.mintDark
                                  : const Color(0xFFDDE4EA),
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            region,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  );
                },
              ),
            ],
          ),
        ),
      );
}

class WeatherHero extends StatelessWidget {
  const WeatherHero({
    super.key,
    required this.schedules,
    required this.weather,
    required this.locationLabel,
    required this.loading,
    required this.onRefresh,
    required this.onLocationTap,
  });
  final List<TodaySchedule> schedules;
  final WeatherSnapshot? weather;
  final String locationLabel;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    final titles = schedules.map((item) => item.title).join(' ');
    var asset = 'assets/characters/chakchak-picnic.png';
    var character = 'picnic';
    var colors = const [
      Color(0xFF3B8F69),
      Color(0xFF58AD78),
      Color(0xFF89C988)
    ];
    if (RegExp(r'여행|공항|비행|출장|휴가|캠핑|숙박').hasMatch(titles)) {
      character = 'travel';
      asset = 'assets/characters/chakchak-travel.png';
      colors = const [Color(0xFF168B8A), Color(0xFF2EAAA5), Color(0xFF70C9BB)];
    } else if (RegExp(r'운동|헬스|러닝|요가|필라테스|수영|등산|축구|테니스').hasMatch(titles)) {
      character = 'exercise';
      asset = 'assets/characters/chakchak-exercise.png';
      colors = const [Color(0xFFF08A46), Color(0xFFF6AA54), Color(0xFFF3C66E)];
    } else if (RegExp(r'데이트|소개팅|기념일|결혼식|약속').hasMatch(titles)) {
      character = 'date';
      asset = 'assets/characters/chakchak-date.png';
      colors = const [Color(0xFFD86685), Color(0xFFE9879D), Color(0xFFEFA8AE)];
    } else if (RegExp(r'피크닉|소풍|공원|나들이|놀이공원|해변|바다').hasMatch(titles)) {
      character = 'picnic';
      asset = 'assets/characters/chakchak-picnic.png';
    } else if (RegExp(r'출근|회사|업무|회의|미팅|면접|발표|세미나|오피스').hasMatch(titles)) {
      character = 'business';
      asset = 'assets/characters/chakchak-business.png';
      colors = const [Color(0xFF3D506F), Color(0xFF5D7191), Color(0xFF8495AD)];
    } else if (RegExp(r'공부|스터디|도서관|수업|강의|시험|과제|독서|학원').hasMatch(titles)) {
      character = 'study';
      asset = 'assets/characters/chakchak-study.png';
      colors = const [Color(0xFF59609B), Color(0xFF757DB3), Color(0xFF9DA3CA)];
    }
    final temperature = weather?.temperature.round() ?? 28;
    final weatherCode = weather?.weatherCode ?? 0;
    final precipitation = weather?.precipitationProbability.round() ?? 0;
    final rainCodes = <int>{
      51,
      53,
      55,
      56,
      57,
      61,
      63,
      65,
      66,
      67,
      80,
      81,
      82,
      95,
      96,
      99
    };
    final isRain = rainCodes.contains(weatherCode) || precipitation >= 50;
    if (isRain) {
      character = 'rain';
      asset = 'assets/characters/chakchak-rain.png';
      colors = const [Color(0xFF486F9F), Color(0xFF6798C4), Color(0xFF85B7D4)];
    } else if (temperature >= 33) {
      character = 'heatwave';
      asset = 'assets/characters/chakchak-heatwave.png';
      colors = const [Color(0xFFE7584F), Color(0xFFF17955), Color(0xFFF5A05C)];
    } else if (temperature <= 5) {
      character = 'coldwave';
      asset = 'assets/characters/chakchak-coldwave.png';
      colors = const [Color(0xFF526D9D), Color(0xFF708FC0), Color(0xFF91ACD0)];
    }
    final apparentTemperature = weather?.apparentTemperature.round() ?? 30;
    final humidity = weather?.humidity.round() ?? 48;
    final rawWind = weather?.windSpeed ?? 2;
    final windSpeed = rawWind == rawWind.roundToDouble()
        ? rawWind.round().toString()
        : rawWind.toStringAsFixed(1);
    final condition = switch (weatherCode) {
      0 => '맑음',
      1 || 2 => '대체로 맑음',
      3 => '흐림',
      45 || 48 => '안개',
      51 || 53 || 55 || 56 || 57 => '이슬비',
      61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => '비',
      71 || 73 || 75 || 77 || 85 || 86 => '눈',
      95 || 96 || 99 => '뇌우',
      _ => weather == null ? '맑음' : '날씨 정보',
    };
    final bubble = loading
        ? '현재 위치의 날씨를 확인하고 있어요.'
        : switch (character) {
            'rain' => '비 올 확률이 $precipitation%예요. 우산과 가벼운 방수 아우터를 챙길까요?',
            'heatwave' => '현재 $temperature°로 무척 더워요. 얇고 통기성 좋은 옷으로 시원하게 입어요.',
            'coldwave' => '현재 $temperature°예요. 패딩과 목도리로 체온을 단단히 지켜요.',
            'travel' => '여행 일정이 있어요. 오래 이동해도 편하고 사진에도 잘 나오는 코디로 골라볼까요?',
            'exercise' =>
              '현재 $temperature°예요. 운동 일정에 맞춰 통기성 좋은 옷과 편한 신발로 준비할까요?',
            'date' => '오늘 데이트가 있네요. 편안하면서도 기분 좋은 포인트가 있는 코디는 어때요?',
            'picnic' => '야외 일정에 햇빛을 가려줄 모자와 가볍게 움직이기 좋은 옷을 챙겨요.',
            'business' => '오늘 일정에는 단정한 인상과 편안한 활동성을 함께 챙겨볼까요?',
            'study' => '오래 집중해도 편안하도록 부드러운 소재와 가벼운 겉옷을 추천할게요.',
            _ => '$condition 날씨예요. 오늘 일정에 맞춰 가볍게 코디해볼까요?',
          };
    return Container(
      key: const ValueKey('home-weather-hero'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(children: [
        Positioned(
          right: -70,
          top: 110,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0x30FFFFFF)),
            ),
          ),
        ),
        Positioned(
          left: -100,
          bottom: -60,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0x1FFFFFFF)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              height: 32,
              child: Row(children: [
                Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: const [
                      Text('착착',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      SizedBox(width: 4),
                      Text('CHAKCHAK',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1)),
                    ]),
                const Spacer(),
                Semantics(
                  button: true,
                  label: '실시간 날씨 새로고침',
                  child: GestureDetector(
                    onTap: loading ? null : onRefresh,
                    behavior: HitTestBehavior.opaque,
                    child: Opacity(
                      opacity: loading ? .65 : 1,
                      child: Container(
                        width: 38,
                        height: 32,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFFFFFF),
                          border: Border.all(color: const Color(0x38FFFFFF)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: SvgPicture.asset('assets/icons/refresh.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: '날씨 지역 변경, 현재 $locationLabel',
              child: GestureDetector(
                onTap: onLocationTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SvgPicture.asset('assets/icons/map.svg',
                        width: 17,
                        height: 17,
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn)),
                    const SizedBox(width: 5),
                    Text(locationLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 11),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFDFA),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(5)),
                  ),
                  child: Text(bubble,
                      style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.42,
                          letterSpacing: -.25)),
                ),
                Positioned(
                  right: 32,
                  bottom: -9,
                  child: CustomPaint(
                      size: const Size(12, 11), painter: _WeatherBubbleTail()),
                ),
              ]),
            ),
            SizedBox(
              height: 143,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 4, 2, 0),
                child: Stack(clipBehavior: Clip.none, children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: .48,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatKoreanHeroDate(DateTime.now()),
                                maxLines: 1,
                                style: const TextStyle(
                                    color: Color(0xD6FFFFFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('$temperature°',
                                maxLines: 1,
                                style: ChakchakTypography.weather.copyWith(
                                  color: Colors.white,
                                )),
                            const SizedBox(height: 7),
                            Text('$condition · 체감 $apparentTemperature°',
                                maxLines: 1,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ),
                  ),
                  Positioned(
                      right: -13,
                      bottom: -19,
                      child: Image.asset(asset,
                          width: 202,
                          height: 202,
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter)),
                ]),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                  decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      border: Border.all(color: const Color(0x2BFFFFFF)),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    for (final stat in [
                      ('체감', '$apparentTemperature°'),
                      ('강수', '$precipitation%'),
                      ('바람', '${windSpeed}m/s'),
                      ('습도', '$humidity%')
                    ])
                      Expanded(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(stat.$1,
                            style: const TextStyle(
                                color: Color(0xBDFFFFFF), fontSize: 9)),
                        const SizedBox(height: 3),
                        Text(stat.$2,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ])),
                  ]),
                ),
              ),
            ),
          ]),
        ),
        const Positioned(
            left: 26,
            right: 26,
            top: 10,
            child: _PhoneTopBar(color: Colors.white)),
        Positioned(
          right: 19,
          bottom: 5,
          child: Text('날씨 제공: ${weather?.sourceLabel ?? '기상청'}',
              style: const TextStyle(
                  color: Color(0x9CFFFFFF), fontSize: 7, letterSpacing: .1)),
        ),
      ]),
    );
  }
}

class _WeatherBubbleTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFFDFA));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard(
      {required this.schedules, required this.onAdd, required this.onDelete});
  final List<TodaySchedule> schedules;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final ordered = [...schedules]..sort((a, b) => a.time.compareTo(b.time));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('오늘의 일정',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
              const SizedBox(height: 4),
              Text(
                  '${formatKoreanDate(DateTime.now())} · ${ordered.isEmpty ? '등록된 일정 없음' : '${ordered.length}개의 일정'}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF73807C), height: 1.25)),
            ])),
        GestureDetector(
          onTap: onAdd,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AppColors.mintDark, shape: BoxShape.circle),
            child: const Text('＋',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      if (ordered.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.line),
                  bottom: BorderSide(color: AppColors.line))),
          child: const Text('＋ 버튼을 눌러 오늘 일정을 추가해보세요.',
              style: TextStyle(fontSize: 11, color: Color(0xFF7A8581))),
        )
      else
        Column(children: [
          for (final item in ordered)
            Container(
              height: 50,
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line))),
              child: Row(children: [
                SizedBox(
                    width: 54,
                    child: Text(item.time,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mintDark,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700))),
                GestureDetector(
                  onTap: () => onDelete(item.id),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text('×',
                          style: TextStyle(
                              color: Color(0xFF98A19E), fontSize: 18)),
                    ),
                  ),
                ),
              ]),
            ),
          const Divider(height: 1, color: AppColors.line),
        ]),
    ]);
  }
}

class OutfitCard extends StatelessWidget {
  const OutfitCard(
      {super.key,
      required this.saved,
      required this.onSave,
      required this.onAskMate,
      required this.garments,
      this.onOutfitToggle,
      this.weather,
      this.mateSelectedOutfit,
      required this.scheduleContext,
      this.variationIndex = 0,
      this.onRefresh});
  final bool saved;
  final VoidCallback onSave;
  final void Function(_TodayOutfitRecommendation outfit, bool selected)?
      onOutfitToggle;
  final VoidCallback onAskMate;
  final List<GarmentItem> garments;
  final WeatherSnapshot? weather;
  final List<GarmentItem>? mateSelectedOutfit;
  final String scheduleContext;
  final int variationIndex;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final recommendedOutfit = _recommendTodayOutfit(
      garments: garments,
      weather: weather,
      scheduleContext: scheduleContext,
      variationIndex: variationIndex,
    );
    GarmentItem? selectedCategory(String category) {
      final selected = mateSelectedOutfit;
      if (selected == null) return null;
      for (final item in selected) {
        if (item.category == category) return item;
      }
      return null;
    }

    final hasMateOutfit = mateSelectedOutfit != null &&
        mateSelectedOutfit!.where((item) => item.name.isNotEmpty).length >= 2;
    final outfit = hasMateOutfit
        ? _TodayOutfitRecommendation(
            top: selectedCategory('상의') ?? recommendedOutfit.top,
            bottom: selectedCategory('하의') ?? recommendedOutfit.bottom,
            shoes: selectedCategory('신발'),
            outer: selectedCategory('아우터'),
            dress: selectedCategory('원피스'),
            title: mateSelectedOutfit!.map((item) => item.name).join(' · '),
            description: '메이트와 함께 고른 오늘의 코디예요.',
          )
        : recommendedOutfit;
    final temperature = weather?.temperature.round() ?? 28;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const _Pill(label: "TODAY'S PICK", color: AppColors.mintDark),
        const Spacer(),
        Semantics(
          button: true,
          label: '다른 코디 보기',
          child: GestureDetector(
            onTap: onRefresh,
            behavior: HitTestBehavior.opaque,
            child: Container(
              key: const ValueKey('today-outfit-refresh'),
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(ChakchakRadii.control)),
              child: SvgPicture.asset('assets/icons/refresh.svg',
                  width: 19,
                  height: 19,
                  colorFilter:
                      const ColorFilter.mode(AppColors.ink, BlendMode.srcIn)),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      _EditorialOutfitFlatLay(
        top: outfit.top,
        bottom: outfit.bottom,
        shoes: outfit.shoes,
        outer: outfit.outer,
        dress: outfit.dress,
      ),
      const SizedBox(height: 14),
      Text(outfit.title, style: ChakchakTypography.card),
      const SizedBox(height: ChakchakSpacing.sm),
      Text(outfit.description,
          style: ChakchakTypography.bodyLight.copyWith(
            color: ChakchakColors.textStrongSecondary,
          )),
      const SizedBox(height: 15),
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 17, color: AppColors.mintDark),
            const SizedBox(width: 7),
            Expanded(
                child: Text(
                    scheduleContext.isEmpty
                        ? '$temperature°의 날씨와 편안한 하루를 고려했어요.'
                        : '$temperature° 날씨와 $scheduleContext 일정을 고려했어요.',
                    style: const TextStyle(
                        fontSize: AppA11y.captionSize,
                        fontWeight: FontWeight.w600)))
          ])),
      const SizedBox(height: 16),
      Semantics(
        button: true,
        toggled: saved,
        label: saved ? '오늘의 픽 선택 취소' : '오늘의 픽으로 선택',
        child: GestureDetector(
          onTap: () {
            onSave();
            onOutfitToggle?.call(outfit, !saved);
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: saved ? AppColors.mintDark : Colors.white,
                border: Border.all(
                    color: saved ? AppColors.mintDark : AppColors.line),
                borderRadius: BorderRadius.circular(AppRadius.control)),
            child: Row(children: [
              SvgPicture.asset('assets/icons/heart.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                      saved ? Colors.white : AppColors.ink, BlendMode.srcIn)),
              const SizedBox(width: ChakchakSpacing.iconGap),
              Expanded(
                  child: Text(saved ? '오늘의 픽으로 선택했어요' : '오늘의 픽으로 선택',
                      style: TextStyle(
                          color: saved ? Colors.white : AppColors.ink,
                          fontSize: 16,
                          height: 1,
                          fontWeight: FontWeight.w500))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 24,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: saved
                        ? const Color(0x66FFFFFF)
                        : const Color(0xFFE3E7E5),
                    borderRadius: BorderRadius.circular(99)),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment:
                      saved ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
          onPressed: onAskMate,
          icon: SvgPicture.asset('assets/icons/nav-mate.svg',
              width: 20, height: 20),
          label: const Text('메이트에게 다른 코디 물어보기'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line))),
    ]);
  }
}

class _TodayOutfitRecommendation {
  const _TodayOutfitRecommendation({
    required this.top,
    required this.bottom,
    required this.shoes,
    required this.outer,
    this.dress,
    required this.title,
    required this.description,
  });

  final GarmentItem top;
  final GarmentItem bottom;
  final GarmentItem? shoes;
  final GarmentItem? outer;
  final GarmentItem? dress;
  final String title;
  final String description;
}

_TodayOutfitRecommendation _recommendTodayOutfit({
  required List<GarmentItem> garments,
  required WeatherSnapshot? weather,
  required String scheduleContext,
  int variationIndex = 0,
}) {
  final temperature = weather?.temperature.round() ?? 28;
  final precipitation = weather?.precipitationProbability.round() ?? 0;
  final schedule = scheduleContext.toLowerCase();
  final isBusiness = RegExp(r'출근|출장|회사|업무|회의|미팅|면접|발표|오피스').hasMatch(schedule);
  final isDate = RegExp(r'데이트|소개팅|기념일|결혼식|약속').hasMatch(schedule);
  final isExercise = RegExp(r'운동|헬스|러닝|요가|필라테스|등산|축구|테니스').hasMatch(schedule);
  final isTravel = RegExp(r'여행|관광|휴가|공항|비행|캠핑|제주').hasMatch(schedule);
  final isRain = precipitation >= 50 ||
      const <int>{
        51,
        53,
        55,
        56,
        57,
        61,
        63,
        65,
        66,
        67,
        80,
        81,
        82,
        95,
        96,
        99,
      }.contains(weather?.weatherCode);

  GarmentItem pick(
    String category,
    GarmentItem fallback,
    int Function(GarmentItem item) score, {
    int offset = 0,
    bool Function(GarmentItem item)? isEligible,
  }) {
    final categoryItems =
        garments.where((item) => item.category == category).toList();
    final eligibleItems = isEligible == null
        ? categoryItems
        : categoryItems.where(isEligible).toList();
    final candidates = eligibleItems.isNotEmpty ? eligibleItems : categoryItems;
    if (candidates.isEmpty) return fallback;
    candidates.sort((a, b) => score(b).compareTo(score(a)));
    final poolSize = min(3, candidates.length);
    final rank =
        variationIndex == 0 ? 0 : (variationIndex - 1 + offset) % poolSize;
    return candidates[rank];
  }

  int neutralColorScore(GarmentItem item) {
    if (RegExp(r'화이트|아이보리|베이지').hasMatch(item.color)) return 3;
    if (RegExp(r'블랙|그레이|네이비').hasMatch(item.color)) return 2;
    return 0;
  }

  int brightDateScore(GarmentItem item) =>
      RegExp(r'핑크|코랄|레드|옐로|라벤더|민트|라이트 블루|아이보리|크림|화이트').hasMatch(item.color)
          ? 5
          : 0;

  bool isTemperatureAppropriateTop(GarmentItem item) {
    final descriptor = '${item.name} ${item.detailCategory}';
    if (temperature >= 27) {
      return RegExp(r'반팔|민소매|나시|슬리브리스').hasMatch(descriptor);
    }
    if (temperature >= 23) {
      return !RegExp(r'기모|패딩|두꺼운|울|후드').hasMatch(descriptor);
    }
    if (temperature <= 10) {
      return !RegExp(r'린넨|반팔|민소매|나시').hasMatch(descriptor);
    }
    return true;
  }

  final top = pick('상의', sampleGarments[0], (item) {
    var score = neutralColorScore(item);
    final detail = item.detailCategory;
    if (temperature >= 28) {
      if (detail.contains('민소매')) score += 13;
      if (detail.contains('반팔')) score += 10;
      if (RegExp(r'긴팔|후드').hasMatch(detail)) score -= 5;
    } else if (temperature >= 23) {
      if (detail.contains('반팔')) score += 9;
    } else if (temperature >= 20) {
      if (detail.contains('셔츠')) score += 9;
    } else if (temperature >= 17) {
      if (detail.contains('후드')) score += 9;
    } else if (temperature <= 16) {
      if (RegExp(r'긴팔|후드|셔츠').hasMatch(detail)) score += 6;
      if (RegExp(r'반팔|민소매').hasMatch(detail)) score -= 4;
    }
    if (isBusiness) {
      if (temperature >= 24 && detail.contains('반팔')) score += 5;
      if (detail.contains('셔츠')) score += 4;
      if (item.color == '화이트') score += 3;
    }
    if (isDate && RegExp(r'셔츠|반팔|긴팔').hasMatch(detail)) {
      score += 4 + brightDateScore(item);
    }
    if (isExercise && RegExp(r'반팔|민소매|후드').hasMatch(detail)) score += 8;
    if (isTravel && RegExp(r'반팔|긴팔|후드|데님').hasMatch(detail)) {
      score += 7;
    }
    return score;
  }, offset: 0, isEligible: isTemperatureAppropriateTop);

  final bottom = pick('하의', sampleGarments[1], (item) {
    var score = neutralColorScore(item);
    final detail = item.detailCategory;
    if (isBusiness && RegExp(r'슬랙스|스트레이트 팬츠').hasMatch(detail)) {
      score += 8;
    }
    if (isDate && RegExp(r'슬랙스|데님').hasMatch(detail)) score += 5;
    if (isExercise && RegExp(r'조거|반바지|버뮤다').hasMatch(detail)) {
      score += 9;
    }
    if (isTravel && RegExp(r'조거|카고|데님|반바지|버뮤다').hasMatch(detail)) {
      score += 8;
    }
    if (temperature >= 30 &&
        !isBusiness &&
        RegExp(r'반바지|버뮤다').hasMatch(detail)) {
      score += 7;
    }
    if (item.color == '블랙') score += 2;
    return score;
  }, offset: 1);

  final shoes = pick('신발', sampleGarments[2], (item) {
    var score = neutralColorScore(item);
    final detail = item.detailCategory;
    if ((isBusiness || isDate) && detail.contains('로퍼')) score += 9;
    if (isExercise && detail.contains('러닝')) score += 10;
    if (isTravel && RegExp(r'스니커즈|러닝').hasMatch(detail)) score += 9;
    if (isRain && RegExp(r'스니커즈|러닝').hasMatch(detail)) score += 5;
    return score;
  }, offset: 2);

  GarmentItem? dress;
  if (isDate &&
      temperature < 28 &&
      garments.any((item) => item.category == '원피스')) {
    dress = pick('원피스', garments.firstWhere((item) => item.category == '원피스'),
        (item) {
      var score = 12 + brightDateScore(item);
      if (temperature <= 8 && item.detailCategory.contains('긴팔')) score += 3;
      return score;
    });
  }

  GarmentItem? outer;
  if (garments.any((item) => item.category == '아우터') &&
      (temperature <= 22 || isRain)) {
    outer = pick(
        '아우터',
        sampleGarments[3],
        (item) {
          var score = neutralColorScore(item);
          final detail = item.detailCategory;
          if (isRain && RegExp(r'바람막이|트렌치').hasMatch(detail)) score += 12;
          if (temperature <= 4 && detail.contains('패딩')) score += 16;
          if (temperature >= 5 && temperature <= 8 && detail.contains('코트'))
            score += 13;
          if (temperature >= 9 &&
              temperature <= 11 &&
              RegExp(r'트렌치|재킷|봄버|데님').hasMatch(detail)) score += 12;
          if (temperature >= 12 &&
              temperature <= 16 &&
              RegExp(r'가디건|후드 집업|패딩 조끼').hasMatch(detail)) score += 11;
          if (temperature >= 17 &&
              temperature <= 19 &&
              RegExp(r'바람막이|후드 집업').hasMatch(detail)) score += 11;
          if (temperature >= 20 &&
              temperature <= 22 &&
              RegExp(r'가디건|바람막이').hasMatch(detail)) score += 7;
          if (temperature >= 23 && RegExp(r'가디건|바람막이').hasMatch(detail))
            score += 3;
          if (isBusiness && RegExp(r'블레이저|가디건|트렌치|코트').hasMatch(detail)) {
            score += 5;
          }
          if (isDate && RegExp(r'가디건|데님 재킷|숏 코트').hasMatch(detail)) {
            score += 5;
          }
          if (isTravel && RegExp(r'바람막이|후드 집업|데님|봄버').hasMatch(detail)) {
            score += 7;
          }
          return score;
        },
        offset: 3,
        isEligible: (item) {
          final descriptor = '${item.name} ${item.detailCategory}';
          if (temperature >= 23) {
            return isRain && RegExp(r'바람막이|레인|우비').hasMatch(descriptor);
          }
          if (temperature >= 17) {
            return !RegExp(r'패딩|두꺼운|롱 코트|숏 코트').hasMatch(descriptor);
          }
          return true;
        });
  }

  final title = dress == null ? '${top.name}와 ${bottom.name}' : dress.name;
  final description = isRain
      ? '비 소식에 대비하면서 오늘 일정에도 자연스럽게 어울리는 조합이에요.'
      : isExercise
          ? '움직이기 편하고 체온 조절이 쉬운 아이템으로 골랐어요.'
          : isDate
              ? '편안함은 유지하면서 은은한 포인트가 살아나는 조합이에요.'
              : isBusiness
                  ? '단정한 인상과 활동성을 함께 챙길 수 있는 조합이에요.'
                  : isTravel
                      ? '이동하기 편하고 가벍게 겹쳐 입기 좋은 조합이에요.'
                      : '$temperature° 날씨에 부담 없이 입기 좋은 조합이에요.';

  return _TodayOutfitRecommendation(
    top: top,
    bottom: bottom,
    shoes: shoes,
    outer: outer,
    dress: dress,
    title: title,
    description: description,
  );
}

class _EditorialOutfitFlatLay extends StatelessWidget {
  const _EditorialOutfitFlatLay({
    required this.top,
    required this.bottom,
    required this.shoes,
    this.outer,
    this.dress,
  });

  final GarmentItem top;
  final GarmentItem bottom;
  final GarmentItem? shoes;
  final GarmentItem? outer;
  final GarmentItem? dress;

  void _openDetail(BuildContext context, GarmentItem item) {
    showGarmentDetailSheet(context, item: item);
  }

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('today-editorial-flatlay'),
        width: double.infinity,
        height: 320,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EC),
          borderRadius: BorderRadius.circular(AppRadius.media),
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (dress == null)
                Positioned(
                  left: width * .5 - 76,
                  top: 92,
                  child: _EditorialGarmentPiece(
                    item: bottom,
                    width: 152,
                    height: 218,
                    rotation: -.018,
                    onTap: () => _openDetail(context, bottom),
                  ),
                ),
              if (dress == null)
                Positioned(
                  left: 16,
                  top: 8,
                  child: _EditorialGarmentPiece(
                    item: top,
                    width: width * .46,
                    height: 148,
                    rotation: -.055,
                    onTap: () => _openDetail(context, top),
                  ),
                ),
              if (dress != null)
                Positioned(
                  left: width * .22,
                  top: 10,
                  child: _EditorialGarmentPiece(
                    item: dress!,
                    width: width * .52,
                    height: 285,
                    rotation: -.025,
                    onTap: () => _openDetail(context, dress!),
                  ),
                ),
              if (outer != null)
                Positioned(
                  right: -8,
                  top: 50,
                  child: _EditorialGarmentPiece(
                    item: outer!,
                    width: width * .49,
                    height: 174,
                    rotation: .045,
                    onTap: () => _openDetail(context, outer!),
                  ),
                ),
              if (shoes != null)
                Positioned(
                  left: 4,
                  bottom: 10,
                  child: _EditorialGarmentPiece(
                    item: shoes!,
                    width: width * .42,
                    height: 92,
                    rotation: -.06,
                    onTap: () => _openDetail(context, shoes!),
                  ),
                ),
            ],
          );
        }),
      );
}

class _EditorialGarmentPiece extends StatelessWidget {
  const _EditorialGarmentPiece({
    required this.item,
    required this.width,
    required this.height,
    required this.onTap,
    this.rotation = 0,
  });

  final GarmentItem item;
  final double width;
  final double height;
  final double rotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${item.name} 상세 보기',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.translucent,
          child: Transform.rotate(
            angle: rotation,
            child: SizedBox(
              key: ValueKey('today-outfit-${item.name}'),
              width: width,
              height: height,
              child: item.imageBytes != null
                  ? Image.memory(item.imageBytes!, fit: BoxFit.contain)
                  : item.assetPath != null
                      ? item.colorizeAsset && item.tintColor != null
                          ? ColorizedGarmentAsset(
                              assetPath: item.assetPath!,
                              color: item.tintColor!,
                              fit: BoxFit.contain,
                              semanticLabel: item.name,
                            )
                          : Image.asset(item.assetPath!,
                              fit: BoxFit.contain, semanticLabel: item.name)
                      : const Icon(Icons.checkroom_outlined,
                          color: AppColors.mintDark),
            ),
          ),
        ),
      );
}

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen(
      {super.key,
      required this.garments,
      required this.onAdd,
      required this.onUpdate,
      this.onAskMate,
      required this.outfitSaved,
      this.savedOutfits = const []});
  final List<GarmentItem> garments;
  final VoidCallback onAdd;
  final void Function(GarmentItem previous, GarmentItem updated) onUpdate;
  final ValueChanged<GarmentItem>? onAskMate;
  final bool outfitSaved;
  final List<SavedOutfitRecord> savedOutfits;

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  String filter = '전체';
  String query = '';

  @override
  Widget build(BuildContext context) {
    final visible = widget.garments
        .where((item) =>
            (filter == '전체' || item.category == filter) &&
            '${item.name}${item.color}${item.location}'.contains(query))
        .toList();
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 42, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height: 32,
                  child: Row(children: [
                    const Text('내 옷장', style: ChakchakTypography.section),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text('${widget.garments.length}벌',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7)),
                    ),
                  ])),
              const SizedBox(height: 20),
              Container(
                height: 43.5,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Text('⌕',
                      style: TextStyle(color: Color(0xFF71807C), fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                    onChanged: (value) => setState(() => query = value),
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      hintText: '이름, 색상, 보관 위치 검색',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Color(0xFF71807C)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  )),
                ]),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SavedOutfitsScreen(
                          hasSavedOutfit: widget.outfitSaved,
                          records: widget.savedOutfits,
                          garments: widget.garments,
                        ))),
                child: Container(
                  height: 68,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: ChakchakColors.brandSubtle,
                      borderRadius:
                          BorderRadius.circular(ChakchakRadii.control),
                      border:
                          Border.all(color: ChakchakColors.borderBrandSubtle)),
                  child: Row(children: [
                    SizedBox(
                        width: 28,
                        height: 28,
                        child: Center(
                            child: SvgPicture.asset('assets/icons/heart.svg',
                                width: 26, height: 26))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('착용 기록',
                              style: TextStyle(
                                  fontSize: 10, color: Color(0xFF74827D))),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Text('오늘의 픽',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 5),
                            Container(
                                constraints: const BoxConstraints(minWidth: 20),
                                height: 20,
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    borderRadius: BorderRadius.circular(
                                        ChakchakRadii.full)),
                                child: Text('${widget.savedOutfits.length}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10))),
                          ]),
                        ])),
                    const Text('›',
                        style:
                            TextStyle(fontSize: 24, color: Color(0xFF73807C))),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 6,
                  separatorBuilder: (_, __) => const SizedBox(width: 7),
                  itemBuilder: (context, index) {
                    const sourceFilters = [
                      '전체',
                      '상의',
                      '하의',
                      '아우터',
                      '원피스',
                      '신발'
                    ];
                    final value = sourceFilters[index];
                    final selected = filter == value;
                    return GestureDetector(
                      onTap: () => setState(() => filter = value),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(
                          horizontal: ChakchakSpacing.controlHorizontal,
                          vertical: ChakchakSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.mint : Colors.white,
                          border: Border.all(
                              color:
                                  selected ? AppColors.mint : AppColors.line),
                          borderRadius:
                              BorderRadius.circular(ChakchakRadii.card),
                        ),
                        child: Text(value,
                            style: TextStyle(
                                fontSize: 15,
                                height: 1,
                                fontWeight: FontWeight.w400,
                                color:
                                    selected ? Colors.white : AppColors.ink)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 86),
                  itemCount: visible.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 183,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    return _WardrobeItem(
                      item: item,
                      onTap: () => showGarmentDetailSheet(
                        context,
                        item: item,
                        onAskMate: widget.onAskMate,
                        onChanged: (updated) {
                          widget.onUpdate(item, updated);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Positioned(left: 26, right: 26, top: 10, child: _PhoneTopBar()),
        Positioned(
          right: 20,
          bottom: 16,
          child: GestureDetector(
            onTap: widget.onAdd,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: AppColors.mint,
                  border: Border.all(color: ChakchakColors.borderSubtle),
                  borderRadius: BorderRadius.circular(ChakchakRadii.control)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('＋',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w500)),
                SizedBox(width: ChakchakSpacing.iconGap),
                Text('새 옷 등록',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

class _WardrobeItem extends StatelessWidget {
  const _WardrobeItem({required this.item, required this.onTap});
  final GarmentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 183,
          padding: const EdgeInsets.all(10),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ChakchakColors.borderDefault)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: GarmentVisual(
                      item: item,
                      size: double.infinity,
                      fillUploadedPhoto: true,
                      radius: 14)),
              const SizedBox(height: 8),
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChakchakTypography.labelStrong),
              const SizedBox(height: 3),
              Text(
                [
                  if (item.detailCategory.isNotEmpty) item.detailCategory,
                  item.color,
                  if (item.location.isNotEmpty) item.location,
                ].join(' · '),
                style: ChakchakTypography.caption.copyWith(
                  color: ChakchakColors.textDisabled,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
}

Future<void> showGarmentDetailSheet(
  BuildContext context, {
  required GarmentItem item,
  ValueChanged<GarmentItem>? onChanged,
  ValueChanged<GarmentItem>? onAskMate,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      barrierColor: const Color(0x66192420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => FractionallySizedBox(
        heightFactor: .92,
        child: GarmentDetailScreen(
          item: item,
          onChanged: onChanged,
          onAskMate: onAskMate,
          asBottomSheet: true,
        ),
      ),
    );

class GarmentDetailScreen extends StatefulWidget {
  const GarmentDetailScreen({
    super.key,
    required this.item,
    this.onChanged,
    this.onAskMate,
    this.asBottomSheet = false,
  });
  final GarmentItem item;
  final ValueChanged<GarmentItem>? onChanged;
  final ValueChanged<GarmentItem>? onAskMate;
  final bool asBottomSheet;

  @override
  State<GarmentDetailScreen> createState() => _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends State<GarmentDetailScreen> {
  late GarmentItem item;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<GarmentItem>(
      MaterialPageRoute(
        builder: (_) => AddGarmentScreen(
          title: '옷 정보 수정',
          initialItem: item,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => item = updated);
    widget.onChanged?.call(updated);
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '미입력';
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}.';
  }

  Color _itemColor() {
    if (item.tintColor case final color?) return color;
    for (final option in garmentColorOptions) {
      if (option.name == item.color) return option.color;
    }
    if (item.color.startsWith('#') && item.color.length == 7) {
      final value = int.tryParse(item.color.substring(1), radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return item.tone;
  }

  Widget _body(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = min(235.0, constraints.maxHeight * .31);
          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              children: [
                SizedBox(
                  height: 42,
                  child: Row(children: [
                    Text(
                      '옷 상세',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: widget.asBottomSheet ? '닫기' : '뒤로',
                      icon: Icon(widget.asBottomSheet
                          ? Icons.close_rounded
                          : Icons.arrow_back_rounded),
                    ),
                  ]),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: GarmentVisual(
                    item: item,
                    size: double.infinity,
                    radius: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintDark,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      item.detailCategory.isEmpty
                          ? item.category
                          : '${item.category} · ${item.detailCategory}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.1,
                      letterSpacing: -.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    SizedBox(
                      height: 62,
                      child: Row(
                        children: [
                          Expanded(
                            child: _GarmentInfoBox(
                              key: const ValueKey('garment-detail-color'),
                              label: '색상',
                              color: _itemColor(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _GarmentInfoBox(label: '핏', value: item.fit),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _GarmentInfoBox(
                              label: '보관 위치',
                              value:
                                  item.location.isEmpty ? '미입력' : item.location,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 62,
                      child: Row(
                        children: [
                          Expanded(
                            child: _GarmentInfoBox(
                              label: '구매일',
                              value: _dateLabel(item.purchaseDate),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _GarmentInfoBox(
                              label: '최근 착용',
                              value: item.lastWornLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ChakchakButton(
                  label: '수정하기',
                  kind: ChakchakButtonKind.sub,
                  onPressed: _edit,
                ),
                const SizedBox(height: 8),
                ChakchakButton(
                  label: '이 옷으로 코디 물어보기',
                  onPressed: () {
                    final onAskMate = widget.onAskMate;
                    if (onAskMate != null) {
                      Navigator.of(context).pop();
                      onAskMate(item);
                      return;
                    }
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MateChatScreen(pinned: item)));
                  },
                ),
              ],
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) => widget.asBottomSheet
      ? Material(color: AppColors.paper, child: SafeArea(child: _body(context)))
      : Scaffold(
          backgroundColor: AppColors.paper,
          body: SafeArea(child: _body(context)),
        );
}

class _GarmentInfoBox extends StatelessWidget {
  const _GarmentInfoBox(
      {super.key, required this.label, this.value, this.color});
  final String label;
  final String? value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            if (color case final color?)
              Semantics(
                label: '색상 ${color.toARGB32().toRadixString(16)}',
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                ),
              )
            else
              Text(value ?? '미입력',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class SavedOutfitsScreen extends StatefulWidget {
  const SavedOutfitsScreen({
    super.key,
    required this.hasSavedOutfit,
    this.records = const [],
    this.garments = const [],
  });

  final bool hasSavedOutfit;
  final List<SavedOutfitRecord> records;
  final List<GarmentItem> garments;

  @override
  State<SavedOutfitsScreen> createState() => _SavedOutfitsScreenState();
}

class _SavedOutfitsScreenState extends State<SavedOutfitsScreen> {
  String query = '';

  List<SavedOutfitRecord> get _records {
    final source = widget.records.isNotEmpty
        ? widget.records
        : widget.hasSavedOutfit
            ? [
                SavedOutfitRecord(
                  date: DateUtils.dateOnly(DateTime.now()),
                  title: '린넨 셔츠와 블랙 슬랙스',
                  description: '오후 외부 미팅에도 단정하고, 더운 날씨에 가병게 입기 좋아요.',
                  garmentNames: sampleGarments
                      .take(3)
                      .map((item) => item.name)
                      .toList(growable: false),
                )
              ]
            : const <SavedOutfitRecord>[];
    final normalizedQuery = query.trim().toLowerCase();
    final filtered = source.where((record) {
      if (normalizedQuery.isEmpty) return true;
      final searchable = [
        '${record.date.year}년 ${formatKoreanDate(record.date)}',
        record.title,
        record.description,
        ...record.garmentNames,
      ].join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  GarmentItem? _resolveGarment(String name) {
    final candidates = <GarmentItem>[
      ...widget.garments,
      ...starterBasicGarments,
      ...sampleGarments,
    ];
    for (final item in candidates) {
      if (item.name == name) return item;
    }
    return null;
  }

  Widget _garmentTile(GarmentItem item, {double width = 112}) => SizedBox(
        key: ValueKey('saved-outfit-garment-${item.name}'),
        width: width,
        height: 112,
        child: GarmentVisual(item: item, size: 112),
      );

  Widget _garmentGallery(List<GarmentItem> items) {
    if (items.length >= 4) {
      return SizedBox(
        key: const ValueKey('saved-outfit-horizontal-gallery'),
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => _garmentTile(items[index]),
        ),
      );
    }
    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          Expanded(child: _garmentTile(items[index], width: double.infinity)),
          if (index != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _recordCard(SavedOutfitRecord record) {
    final items = record.garmentNames
        .map(_resolveGarment)
        .whereType<GarmentItem>()
        .toList(growable: false);
    return Container(
      key: ValueKey('saved-outfit-${record.date.toIso8601String()}'),
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${record.date.year}년 ${formatKoreanDate(record.date)}',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.mintDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          if (items.isNotEmpty) _garmentGallery(items),
          if (items.isNotEmpty) const SizedBox(height: 15),
          Text(record.title,
              style: const TextStyle(
                  fontSize: 19,
                  height: 1.25,
                  letterSpacing: -.5,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          Text(record.description,
              style: const TextStyle(
                  fontSize: 13, height: 1.45, color: Color(0xFF66736E))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
          backgroundColor: AppColors.paper,
          surfaceTintColor: AppColors.paper,
          centerTitle: true,
          title: const Text('오늘의 픽')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('오늘의 픽으로 선택한 코디 기록이에요.',
                style: TextStyle(fontSize: 14, color: Color(0xFF68746F))),
            const SizedBox(height: 16),
            Container(
              key: const ValueKey('saved-outfit-search'),
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(children: [
                const Icon(Icons.search_rounded,
                    size: 21, color: Color(0xFF71807C)),
                const SizedBox(width: 9),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => query = value),
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      hintText: '날짜, 코디, 옷 이름 검색',
                      hintStyle:
                          TextStyle(fontSize: 14, color: Color(0xFF7A8581)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_border_rounded,
                              size: 46, color: AppColors.mintDark),
                          const SizedBox(height: 12),
                          Text(
                            query.trim().isEmpty
                                ? '아직 오늘의 픽이 없어요'
                                : '검색 결과가 없어요',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            query.trim().isEmpty
                                ? '메인 화면에서 오늘의 픽을 선택하면\n입은 옷으로 기록돼요.'
                                : '다른 날짜나 옷 이름으로 검색해보세요.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF71807B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 28),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) =>
                          _recordCard(records[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacySavedOutfitsScreen extends StatelessWidget {
  const _LegacySavedOutfitsScreen({required this.hasSavedOutfit});
  final bool hasSavedOutfit;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
            backgroundColor: AppColors.paper,
            surfaceTintColor: AppColors.paper,
            title: const Text('오늘의 픽')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: hasSavedOutfit
              ? ListView(children: [
                  const Text('오늘 입은 옷으로 선택한 코디예요.',
                      style: TextStyle(color: Color(0xFF68746F))),
                  const SizedBox(height: 16),
                  Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.line)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              for (final item in sampleGarments.take(3))
                                Expanded(
                                    child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 7),
                                        child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.media),
                                            child: GarmentVisual(
                                                item: item, size: 100))))
                            ]),
                            const SizedBox(height: 13),
                            Text(formatKoreanDate(DateTime.now()),
                                style: const TextStyle(
                                    fontSize: AppA11y.captionSize,
                                    color: AppColors.mintDark,
                                    fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            const Text('린넨 셔츠와 블랙 슬랙스',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 5),
                            const Text('오후 외부 미팅에도 단정하고, 더운 날씨에 가볍게 입기 좋아요.',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF66736E)))
                          ])),
                ])
              : const Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 46, color: AppColors.mintDark),
                  SizedBox(height: 12),
                  Text('아직 오늘의 픽이 없어요',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 7),
                  Text('메인 화면에서 오늘의 픽을 선택하면\n오늘 입은 옶으로 기록돼요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF71807B)))
                ])),
        ),
      );
}

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen(
      {super.key,
      required this.garments,
      this.records = const [],
      this.initialTab = 0,
      this.onWearOutfit});
  final List<GarmentItem> garments;
  final List<SavedOutfitRecord> records;
  final int initialTab;
  final VoidCallback? onWearOutfit;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late int tab;

  List<SavedOutfitRecord> get _lastYearRecords {
    final now = DateTime.now();
    final records = widget.records
        .where((record) =>
            record.date.year == now.year - 1 && record.date.month == now.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (records.isNotEmpty) return records;
    final fallback = demoLastYearOutfits(now)
      ..sort((a, b) => b.date.compareTo(a.date));
    return fallback;
  }

  List<GarmentItem> _recordGarments(SavedOutfitRecord record) {
    final byName = {
      for (final item in starterBasicGarments) item.name: item,
      for (final item in widget.garments) item.name: item,
    };
    return record.garmentNames
        .map((name) => byName[name])
        .whereType<GarmentItem>()
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
            backgroundColor: AppColors.paper,
            surfaceTintColor: AppColors.paper,
            title: const Text('착착의 발견')),
        body: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('지난 코디')),
                    ButtonSegment(value: 1, label: Text('오래 안 입은 옷'))
                  ],
                  selected: {
                    tab
                  },
                  onSelectionChanged: (value) =>
                      setState(() => tab = value.first)),
              const SizedBox(height: 18),
              Expanded(
                  child: tab == 0
                      ? ListView(children: [
                          for (final record in _lastYearRecords)
                            Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                    border: Border.all(color: AppColors.line)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${record.date.year}년 ${record.date.month}월 ${record.date.day}일',
                                          style: const TextStyle(
                                              fontSize: AppA11y.captionSize,
                                              color: AppColors.mintDark,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 5),
                                      Text(record.title,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800)),
                                      if (_recordGarments(record)
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 76,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount:
                                                _recordGarments(record).length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(width: 8),
                                            itemBuilder: (context, index) {
                                              final item = _recordGarments(
                                                  record)[index];
                                              return GarmentVisual(
                                                  item: item,
                                                  size: 76,
                                                  radius: 14);
                                            },
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(record.description,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF66736E))),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                          width: double.infinity,
                                          child: FilledButton(
                                              onPressed: () {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            '오늘 코디로 불러왔어요.'),
                                                        duration: Duration(
                                                            seconds: 1)));
                                                widget.onWearOutfit?.call();
                                              },
                                              style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.mint,
                                                  foregroundColor: Colors.white,
                                                  minimumSize:
                                                      const Size.fromHeight(
                                                          46)),
                                              child: const Text('오늘 코디로 보기')))
                                    ]))
                        ])
                      : ListView(children: [
                          for (final item in widget.garments.skip(3))
                            Card(
                                margin: const EdgeInsets.only(bottom: 11),
                                color: Colors.white,
                                child: ListTile(
                                    onTap: () => showGarmentDetailSheet(context,
                                        item: item),
                                    leading: SizedBox(
                                        width: 62,
                                        height: 62,
                                        child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.media),
                                            child: GarmentVisual(
                                                item: item, size: 62))),
                                    title: Text(item.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    subtitle: Text(
                                        '${item.category} · ${item.color}\n30일 이상 쉬는 중'),
                                    isThreeLine: true,
                                    trailing: const Icon(
                                        Icons.chevron_right_rounded)))
                        ])),
            ])),
      );
}

class AddGarmentScreen extends StatefulWidget {
  const AddGarmentScreen({super.key, this.title = '새 옷 등록', this.initialItem});
  final String title;
  final GarmentItem? initialItem;
  @override
  State<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends State<AddGarmentScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  final imagePicker = ImagePicker();
  String category = garmentCategoryDetails.keys.first;
  late String detailCategory = garmentCategoryDetails[category]!.first;
  String garmentFit = '기본';
  Uint8List? photoBytes;
  GarmentSample? selectedSample;
  GarmentColorOption? selectedColor;
  DateTime? purchaseDate;
  String? existingAssetPath;
  bool existingAssetColorized = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial == null) {
      selectedSample = _sampleFor(category, detailCategory);
      return;
    }
    nameController.text = initial.name;
    locationController.text = initial.location;
    category = garmentCategoryDetails.containsKey(initial.category)
        ? initial.category
        : garmentCategoryDetails.keys.first;
    detailCategory =
        garmentCategoryDetails[category]!.contains(initial.detailCategory)
            ? initial.detailCategory
            : garmentCategoryDetails[category]!.first;
    photoBytes = initial.imageBytes;
    purchaseDate = initial.purchaseDate;
    garmentFit = initial.fit;
    for (final option in garmentColorOptions) {
      if (option.name == initial.color) {
        selectedColor = option;
        break;
      }
    }
    if (selectedColor == null && initial.tintColor != null) {
      selectedColor = GarmentColorOption(
          _colorHex(initial.tintColor!), initial.tintColor!,
          useLightCheck:
              ThemeData.estimateBrightnessForColor(initial.tintColor!) ==
                  Brightness.dark);
    }
    if (initial.assetPath != null) {
      for (final sample in garmentSamples) {
        if (sample.assetPath == initial.assetPath) {
          selectedSample = sample;
          break;
        }
      }
      if (selectedSample == null) {
        existingAssetPath = initial.assetPath;
        existingAssetColorized = initial.colorizeAsset;
      }
    }
  }

  String _colorHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  GarmentSample? _sampleFor(String category, String detailCategory) {
    for (final sample in garmentSamples) {
      if (sample.category == category &&
          sample.detailCategory == detailCategory) {
        return sample;
      }
    }
    return null;
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await imagePicker.pickImage(
          source: source, imageQuality: 82, maxWidth: 1200, maxHeight: 1200);
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (mounted) {
        setState(() {
          photoBytes = bytes;
          selectedSample = null;
          existingAssetPath = null;
        });
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진을 불러오지 못했어요. 사진 접근 권한을 확인해주세요.')));
    }
  }

  Future<void> _selectSample() async {
    var filter = category;
    final sample = await showModalBottomSheet<GarmentSample>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final visible = garmentSamples
              .where((item) => filter == '전체' || item.category == filter)
              .toList();
          return FractionallySizedBox(
            heightFactor: .84,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text('샘플 의류 선택',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final value in [
                          '전체',
                          ...garmentCategoryDetails.keys
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: ChoiceChip(
                              label: Text(value),
                              selected: filter == value,
                              onSelected: (_) =>
                                  setSheetState(() => filter = value),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: .82,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final item = visible[index];
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(item),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F5F2),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(7),
                                      child: ColorizedGarmentAsset(
                                        assetPath: item.assetPath,
                                        color: selectedColor?.color ??
                                            const Color(0xFFD9DDD7),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                    '${item.category} · ${item.detailCategory}',
                                    style: const TextStyle(
                                        fontSize: AppA11y.captionSize,
                                        color: AppColors.muted)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (sample == null || !mounted) return;
    setState(() {
      selectedSample = sample;
      photoBytes = null;
      existingAssetPath = null;
      category = sample.category;
      detailCategory = sample.detailCategory;
      if (nameController.text.trim().isEmpty) {
        nameController.text = sample.name;
      }
    });
  }

  Future<void> _selectPhotoSource() async {
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
                child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('옷 사진 추가',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800))),
                const SizedBox(height: 10),
                ListTile(
                    leading: const Icon(Icons.camera_alt_outlined),
                    title: const Text('카메라로 촬영'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickPhoto(ImageSource.camera);
                    }),
                ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('앨범에서 선택'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _pickPhoto(ImageSource.gallery);
                    }),
              ]),
            )));
  }

  Future<void> _pickCustomColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (_) => _CustomColorPickerDialog(
          initialColor: selectedColor?.color ?? AppColors.mintDark),
    );
    if (color == null || !mounted) return;
    setState(() {
      selectedColor = GarmentColorOption(
        _colorHex(color),
        color,
        useLightCheck:
            ThemeData.estimateBrightnessForColor(color) == Brightness.dark,
      );
    });
  }

  Future<void> _pickPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      helpText: '구매일 선택',
      cancelText: '취소',
      confirmText: '선택',
    );
    if (date != null && mounted) setState(() => purchaseDate = date);
  }

  String get _purchaseDateLabel => purchaseDate == null
      ? '연도. 월. 일.'
      : '${purchaseDate!.year}. ${purchaseDate!.month.toString().padLeft(2, '0')}. ${purchaseDate!.day.toString().padLeft(2, '0')}.';

  void _save() {
    if (selectedColor == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('색상을 선택해주세요.')));
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(GarmentItem(
      name: nameController.text.trim(),
      category: category,
      detailCategory: detailCategory,
      fit: garmentFit,
      color: selectedColor!.name,
      location: locationController.text.trim(),
      tone: const [
        Color(0xFFDFF4EC),
        Color(0xFFF8DFB5),
        Color(0xFFE6DDF5),
        Color(0xFFDCECF7),
        Color(0xFFF8DFE5),
        Color(0xFFE5EFD9)
      ][Random().nextInt(6)],
      assetPath: selectedSample?.assetPath ?? existingAssetPath,
      imageBytes: photoBytes,
      tintColor: selectedSample != null || existingAssetColorized
          ? selectedColor!.color
          : null,
      colorizeAsset: selectedSample != null || existingAssetColorized,
      purchaseDate: purchaseDate,
      registrationMethod: photoBytes != null
          ? '사진 등록'
          : selectedSample != null
              ? '샘플 이미지'
              : widget.initialItem?.registrationMethod ?? '직접 등록',
      lastWornLabel: widget.initialItem?.lastWornLabel ?? '미기록',
    ));
  }

  Widget _imageChoice() {
    final hasVisual = photoBytes != null ||
        selectedSample != null ||
        existingAssetPath != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _GarmentFormLabel(label: '옷 사진', optional: true),
      const SizedBox(height: 10),
      CustomPaint(
        foregroundPainter:
            _DashedRoundRectPainter(color: const Color(0xFF8BAEA4), radius: 22),
        child: Container(
          height: 205,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
              color: const Color(0xFFF1F7F5),
              borderRadius: BorderRadius.circular(AppRadius.card)),
          child: hasVisual
              ? Stack(fit: StackFit.expand, children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: photoBytes != null
                        ? Image.memory(photoBytes!, fit: BoxFit.contain)
                        : selectedSample != null || existingAssetColorized
                            ? ColorizedGarmentAsset(
                                assetPath: selectedSample?.assetPath ??
                                    existingAssetPath!,
                                color: selectedColor?.color ??
                                    const Color(0xFFD9DDD7))
                            : Image.asset(existingAssetPath!,
                                fit: BoxFit.contain),
                  ),
                  if (photoBytes != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: IconButton.filled(
                        tooltip: '사진 삭제',
                        onPressed: () => setState(() {
                          photoBytes = null;
                          existingAssetPath = null;
                          selectedSample = _sampleFor(category, detailCategory);
                        }),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                ])
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_camera_outlined,
                        size: 42, color: AppColors.mintDark),
                    SizedBox(height: 10),
                    Text('사진을 찍거나 앨범에서 고르기',
                        style: TextStyle(
                            color: AppColors.mintDark,
                            fontWeight: FontWeight.w800)),
                    SizedBox(height: 5),
                    Text('사진 없이도 등록할 수 있어요.',
                        style: TextStyle(
                            fontSize: AppA11y.captionSize,
                            color: AppColors.muted)),
                  ],
                ),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectPhotoSource,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(photoBytes == null ? '사진 등록' : '사진 변경'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectSample,
            icon: const Icon(Icons.checkroom_outlined),
            label: Text(selectedSample == null ? '샘플 선택' : '샘플 변경'),
          ),
        ),
      ]),
    ]);
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
            borderSide:
                const BorderSide(color: AppColors.mintDark, width: 1.5)),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.paper,
        body: SafeArea(
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: ChakchakTypography.section),
                        const SizedBox(height: 5),
                        Text(
                            widget.initialItem == null
                                ? '사진과 옷 정보를 등록해주세요.'
                                : '등록된 옷 정보를 수정해주세요.',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: '닫기',
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.mist,
                        foregroundColor: AppColors.muted),
                  ),
                ]),
                const SizedBox(height: 22),
                _imageChoice(),
                const SizedBox(height: 24),
                const _GarmentFormLabel(label: '옷 이름', required: true),
                const SizedBox(height: 9),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 14),
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '옷 이름을 입력해주세요.'
                      : null,
                  decoration: _fieldDecoration('예: 아이보리 린넨 셔츠'),
                ),
                const SizedBox(height: 20),
                const _GarmentFormLabel(label: '카테고리', required: true),
                const SizedBox(height: 9),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: category,
                      isExpanded: true,
                      style:
                          const TextStyle(fontSize: 14, color: AppColors.ink),
                      decoration: _fieldDecoration('상의'),
                      items: [
                        for (final value in garmentCategoryDetails.keys)
                          DropdownMenuItem(value: value, child: Text(value))
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          category = value;
                          detailCategory = garmentCategoryDetails[value]!.first;
                          if (photoBytes == null) {
                            existingAssetPath = null;
                            existingAssetColorized = false;
                            selectedSample =
                                _sampleFor(category, detailCategory);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: detailCategory,
                      isExpanded: true,
                      style:
                          const TextStyle(fontSize: 14, color: AppColors.ink),
                      decoration: _fieldDecoration('반팔티'),
                      items: [
                        for (final value in garmentCategoryDetails[category]!)
                          DropdownMenuItem(value: value, child: Text(value))
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          detailCategory = value;
                          if (photoBytes == null) {
                            existingAssetPath = null;
                            existingAssetColorized = false;
                            selectedSample =
                                _sampleFor(category, detailCategory);
                          }
                        });
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 20),
                const _GarmentFormLabel(label: '핏', required: true),
                const SizedBox(height: 9),
                Row(
                  children: [
                    for (final value in ['슬림', '기본', '루즈']) ...[
                      Expanded(
                        child: GestureDetector(
                          key: ValueKey('garment-fit-$value'),
                          onTap: () => setState(() => garmentFit = value),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: garmentFit == value
                                  ? AppColors.mintDark
                                  : Colors.white,
                              border: Border.all(
                                color: garmentFit == value
                                    ? AppColors.mintDark
                                    : AppColors.line,
                              ),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: garmentFit == value
                                    ? Colors.white
                                    : AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (value != '루즈') const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const _GarmentFormLabel(label: '색상', required: true),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 11,
                  crossAxisSpacing: 11,
                  children: [
                    for (final option in garmentColorOptions)
                      Center(
                        child: _GarmentColorChip(
                          option: option,
                          selected: selectedColor?.name == option.name,
                          onTap: () => setState(() => selectedColor = option),
                        ),
                      ),
                    Center(
                      child: Semantics(
                        button: true,
                        label: '직접 색상 선택',
                        child: InkWell(
                          key: const ValueKey('custom-color-button'),
                          onTap: _pickCustomColor,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(colors: [
                                Colors.red,
                                Colors.yellow,
                                Colors.green,
                                Colors.cyan,
                                Colors.blue,
                                Colors.purple,
                                Colors.red,
                              ]),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedColor != null) ...[
                  const SizedBox(height: 9),
                  Text('선택한 색상: ${selectedColor!.name}',
                      style: const TextStyle(
                          fontSize: AppA11y.captionSize,
                          color: AppColors.muted)),
                ],
                const SizedBox(height: 20),
                const _GarmentFormLabel(label: '보관 위치', optional: true),
                const SizedBox(height: 9),
                TextFormField(
                  controller: locationController,
                  style: const TextStyle(fontSize: 14),
                  textInputAction: TextInputAction.done,
                  maxLength: 30,
                  decoration: _fieldDecoration('예: 안방 옷장'),
                ),
                const SizedBox(height: 20),
                const _GarmentFormLabel(label: '구매일', optional: true),
                const SizedBox(height: 9),
                InkWell(
                  onTap: _pickPurchaseDate,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(children: [
                      Expanded(
                          child: Text(_purchaseDateLabel,
                              style: TextStyle(
                                  color: purchaseDate == null
                                      ? AppColors.muted
                                      : AppColors.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600))),
                      const Icon(Icons.calendar_today_outlined, size: 20),
                    ]),
                  ),
                ),
                const SizedBox(height: 26),
                ChakchakButton(
                  label: widget.initialItem == null ? '옷장에 저장하기' : '수정 내용 저장하기',
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      );
}

class _GarmentFormLabel extends StatelessWidget {
  const _GarmentFormLabel(
      {required this.label, this.required = false, this.optional = false});
  final String label;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(children: [
          if (required)
            const TextSpan(
                text: '* ', style: TextStyle(color: Color(0xFFD26454))),
          TextSpan(text: label),
          if (optional)
            const TextSpan(
                text: '  선택',
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: AppA11y.captionSize,
                    fontWeight: FontWeight.w500)),
        ]),
        style: ChakchakTypography.bodyStrong,
      );
}

class _GarmentColorChip extends StatelessWidget {
  const _GarmentColorChip(
      {required this.option, required this.selected, required this.onTap});
  final GarmentColorOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: '${option.name} 색상',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.mintDark : const Color(0xFFD7D9D5),
                width: selected ? 3 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded,
                    size: 21,
                    color: option.useLightCheck ? Colors.white : AppColors.ink)
                : null,
          ),
        ),
      );
}

class _CustomColorPickerDialog extends StatefulWidget {
  const _CustomColorPickerDialog({required this.initialColor});
  final Color initialColor;

  @override
  State<_CustomColorPickerDialog> createState() =>
      _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<_CustomColorPickerDialog> {
  late HSVColor color;
  late double spectrumX;
  late double spectrumY;

  @override
  void initState() {
    super.initState();
    color = HSVColor.fromColor(widget.initialColor);
    spectrumX = (color.hue / 360).clamp(0.0, 1.0).toDouble();
    spectrumY = _spectrumYFor(color);
  }

  double _spectrumYFor(HSVColor value) {
    if (value.value < .98) {
      return (.5 + ((1 - value.value) / .82) * .5).clamp(.5, 1.0).toDouble();
    }
    return (((value.saturation - .18) / .82) * .5).clamp(0.0, .5).toDouble();
  }

  void _selectFromSpectrum(Offset position, Size size) {
    final x = (position.dx / size.width).clamp(0.0, 1.0).toDouble();
    final y = (position.dy / size.height).clamp(0.0, 1.0).toDouble();
    final saturation =
        y <= .5 ? (.18 + y * 1.64).clamp(0.0, 1.0).toDouble() : 1.0;
    final value =
        y <= .5 ? 1.0 : (1 - (y - .5) * 1.64).clamp(.18, 1.0).toDouble();
    setState(() {
      spectrumX = x;
      spectrumY = y;
      color = HSVColor.fromAHSV(1, x * 360, saturation, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = color.toColor();
    return AlertDialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title:
          const Text('색상 직접 선택', style: TextStyle(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 310,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selected,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('선택한 색상',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(_formatColorHex(selected),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            const Text('그라데이션을 누르거나 끌어서 색을 고르세요.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 9),
            _ColorSpectrumPicker(
              selectedColor: selected,
              x: spectrumX,
              y: spectrumY,
              onChanged: _selectFromSpectrum,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(selected),
          style: FilledButton.styleFrom(backgroundColor: AppColors.mint),
          child: const Text('선택'),
        ),
      ],
    );
  }
}

class _ColorSpectrumPicker extends StatelessWidget {
  const _ColorSpectrumPicker({
    required this.selectedColor,
    required this.x,
    required this.y,
    required this.onChanged,
  });

  final Color selectedColor;
  final double x;
  final double y;
  final void Function(Offset position, Size size) onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '색상 그라데이션',
        value: _formatColorHex(selectedColor),
        slider: true,
        child: LayoutBuilder(builder: (context, constraints) {
          final size = Size(constraints.maxWidth, 188);
          void update(Offset globalPosition) {
            final box = context.findRenderObject()! as RenderBox;
            onChanged(box.globalToLocal(globalPosition), size);
          }

          return GestureDetector(
            key: const ValueKey('custom-color-spectrum'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => onChanged(details.localPosition, size),
            onPanStart: (details) => update(details.globalPosition),
            onPanUpdate: (details) => update(details.globalPosition),
            child: SizedBox(
              height: size.height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0xFFFF3B30),
                          Color(0xFFFFCC00),
                          Color(0xFF34C759),
                          Color(0xFF32ADE6),
                          Color(0xFF007AFF),
                          Color(0xFFAF52DE),
                          Color(0xFFFF2D55),
                          Color(0xFFFF3B30),
                        ]),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xEFFFFFFF),
                            Color(0x00FFFFFF),
                            Color(0xD9000000),
                          ],
                          stops: [0, .5, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: x * size.width - 12,
                    top: y * size.height - 12,
                    child: IgnorePointer(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x55000000),
                                blurRadius: 5,
                                offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                          border: Border.fromBorderSide(
                              BorderSide(color: Color(0x22000000))),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          );
        }),
      );
}

String _formatColorHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _DashedRoundRectPainter extends CustomPainter {
  const _DashedRoundRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final path = Path()
      ..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 7), paint);
        distance += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class MateChatScreen extends StatefulWidget {
  const MateChatScreen({
    super.key,
    this.pinned,
    this.onExit,
    this.garments,
    this.schedules = const [],
    this.weather,
    this.onUseOutfit,
  });
  final GarmentItem? pinned;
  final VoidCallback? onExit;
  final List<GarmentItem>? garments;
  final List<TodaySchedule> schedules;
  final WeatherSnapshot? weather;
  final ValueChanged<List<GarmentItem>>? onUseOutfit;

  @override
  State<MateChatScreen> createState() => _MateChatScreenState();
}

class _MateChatScreenState extends State<MateChatScreen> {
  final textController = TextEditingController();
  late List<ChatLine> lines;
  late List<GarmentItem> selectedGarments;
  BackendService? _backend;
  bool _isReplying = false;
  bool _menuOpen = false;

  BackendService get _mateBackend => _backend ??= BackendService();

  List<GarmentItem> get _wardrobe {
    final wardrobe = List<GarmentItem>.of(widget.garments ?? sampleGarments);
    final pinned = widget.pinned;
    if (pinned != null && !wardrobe.any((item) => item.name == pinned.name)) {
      wardrobe.insert(0, pinned);
    }
    return wardrobe;
  }

  String get _scheduleContext =>
      widget.schedules.map((item) => '${item.time} ${item.title}').join(', ');

  String get _introMessage {
    if (widget.pinned != null) {
      return '${widget.pinned!.name}을 중심으로 오늘 날씨와 일정에 맞는 코디를 골라볼게요.';
    }
    final temperature = widget.weather?.temperature.round() ?? 28;
    final schedule = widget.schedules.isEmpty
        ? '오늘 일정'
        : widget.schedules.map((item) => item.title).join(', ');
    return '오늘은 $temperature°예요. $schedule에 맞추어 입기 좋은 코디를 골라봤어요.';
  }

  List<GarmentItem> _contextOutfitItems() {
    final wardrobe = _wardrobe;
    if (widget.pinned case final pinned?) {
      return _outfitIncludingMentioned([pinned], const [], wardrobe);
    }
    final outfit = _recommendTodayOutfit(
      garments: wardrobe,
      weather: widget.weather,
      scheduleContext: _scheduleContext,
    );
    return [
      if (outfit.dress != null) outfit.dress! else outfit.top,
      if (outfit.dress == null) outfit.bottom,
      if (outfit.shoes != null) outfit.shoes!,
      if (outfit.outer != null) outfit.outer!,
    ].take(3).toList(growable: false);
  }

  String _normalizedGarmentText(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^0-9a-z가-힣]'), '');

  List<GarmentItem> _mentionedGarments(
      String message, List<GarmentItem> wardrobe) {
    final normalizedMessage = _normalizedGarmentText(message);
    return wardrobe.where((item) {
      final normalizedName = _normalizedGarmentText(item.name);
      return normalizedName.length >= 3 &&
          normalizedMessage.contains(normalizedName);
    }).toList(growable: false);
  }

  List<GarmentItem> _outfitIncludingMentioned(
    List<GarmentItem> mentioned,
    List<GarmentItem> aiItems,
    List<GarmentItem> wardrobe,
  ) {
    if (mentioned.isEmpty) {
      return aiItems.isEmpty ? _contextOutfitItems() : aiItems.take(3).toList();
    }
    final required = mentioned.first;
    final baseOutfit = _recommendTodayOutfit(
      garments: wardrobe,
      weather: widget.weather,
      scheduleContext: _scheduleContext,
    );
    final candidates = <GarmentItem>[...aiItems, ...wardrobe];
    GarmentItem? findCategory(String category) {
      for (final item in candidates) {
        if (item.category == category && item.name != required.name)
          return item;
      }
      return null;
    }

    final bottom = findCategory('하의') ?? baseOutfit.bottom;
    final shoes = findCategory('신발') ?? baseOutfit.shoes;
    final top = findCategory('상의') ?? baseOutfit.top;
    final result = switch (required.category) {
      '원피스' => <GarmentItem>[
          required,
          if (shoes != null) shoes,
          if (findCategory('아우터') ?? baseOutfit.outer case final outer?) outer,
        ],
      '상의' => <GarmentItem>[required, bottom, if (shoes != null) shoes],
      '하의' => <GarmentItem>[top, required, if (shoes != null) shoes],
      '신발' => <GarmentItem>[
          if (baseOutfit.dress case final dress?) dress else top,
          if (baseOutfit.dress == null) bottom,
          required,
        ],
      '아우터' => <GarmentItem>[required, top, bottom],
      _ => <GarmentItem>[required, top, bottom],
    };
    return result
        .where((item) => item.name.isNotEmpty)
        .fold<List<GarmentItem>>(<GarmentItem>[], (unique, item) {
          if (!unique.any((candidate) => candidate.name == item.name)) {
            unique.add(item);
          }
          return unique;
        })
        .take(3)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    lines = [
      ChatLine.mate(widget.pinned == null
          ? '오늘은 28°로 더워요. 오후 외부 미팅에 맞춰 가볍고 단정한 코디를 골라봤어요.'
          : '${widget.pinned!.name}을 꼭 입고 싶구나! 이 옷을 중심으로 코디해볼게요.')
    ];
    selectedGarments = (widget.garments ?? sampleGarments).take(3).toList();
    lines = [ChatLine.mate(_introMessage)];
    selectedGarments = _contextOutfitItems();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _send([String? quick]) async {
    final message = quick ?? textController.text.trim();
    if (message.isEmpty || _isReplying) return;
    setState(() {
      lines.add(ChatLine.user(message));
      textController.clear();
      _isReplying = true;
    });
    try {
      final wardrobe = _wardrobe;
      final mentioned = <GarmentItem>[
        if (widget.pinned case final pinned?) pinned,
        ..._mentionedGarments(message, wardrobe)
            .where((item) => item.name != widget.pinned?.name),
      ];
      final liveSchedules = widget.schedules
          .map((item) => <String, Object?>{
                'title': item.title,
                'time': item.time,
                'date': item.effectiveDate.toIso8601String(),
              })
          .toList(growable: false);
      final response = await _mateBackend.recommendOutfit(
        message: widget.pinned == null
            ? message
            : '${widget.pinned!.name}을 반드시 포함해서 $message',
        wardrobe: wardrobe
            .map((item) => {
                  'name': item.name,
                  'category': item.category,
                  'detailCategory': item.detailCategory,
                  'fit': item.fit,
                  'color': item.color,
                })
            .toList(),
        schedules: liveSchedules.isNotEmpty
            ? liveSchedules
            : [
                {'title': '오후 외부 미팅', 'time': '15:00'},
                ...widget.schedules.map((item) => {
                      'title': item.title,
                      'time': item.time,
                      'date': item.effectiveDate.toIso8601String(),
                    }),
              ],
        weather: {
          'temperature': widget.weather?.temperature ?? 28,
          'condition': '맑음',
          'precipitationProbability':
              widget.weather?.precipitationProbability ?? 10,
        },
        history: lines
            .take(max(0, lines.length - 1))
            .map((line) => {
                  'role': line.mine ? 'user' : 'assistant',
                  'content': line.text,
                })
            .toList(),
      );
      final byName = {for (final item in wardrobe) item.name: item};
      if (!mounted) return;
      setState(() {
        lines.add(ChatLine.mate(response.answer));
        final aiItems = response.selectedItemNames
            .map((name) => byName[name])
            .whereType<GarmentItem>()
            .toList();
        selectedGarments =
            _outfitIncludingMentioned(mentioned, aiItems, wardrobe);
      });
    } catch (_) {
      if (!mounted) return;
      final wardrobe = _wardrobe;
      final mentioned = <GarmentItem>[
        if (widget.pinned case final pinned?) pinned,
        ..._mentionedGarments(message, wardrobe)
            .where((item) => item.name != widget.pinned?.name),
      ];
      setState(() {
        lines.add(ChatLine.mate(mentioned.isEmpty
            ? _answerFor(message)
            : '${mentioned.first.name}을 중심으로 어울리는 조합을 골라봤어요.'));
        selectedGarments =
            _outfitIncludingMentioned(mentioned, const [], wardrobe);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('AI 연결이 잠시 불안정해 기본 추천을 보여드려요.'),
      ));
    } finally {
      if (mounted) setState(() => _isReplying = false);
    }
  }

  void _resetChat() {
    setState(() {
      lines = [
        ChatLine.mate(widget.pinned == null
            ? '오늘은 28°로 더워요. 오후 외부 미팅에 맞춰 가병고 단정한 코디를 골라봤어요.'
            : '${widget.pinned!.name}을 꼭 입고 싶구나! 이 옷을 중심으로 코디해볼게요.')
      ];
      lines = [ChatLine.mate(_introMessage)];
      selectedGarments = _contextOutfitItems();
      textController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('대화를 초기화했어요.'), duration: Duration(seconds: 1)));
  }

  void _exitChat() {
    if (widget.onExit != null) {
      widget.onExit!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  String _answerFor(String input) {
    if (input.contains('비'))
      return '지금 예보에는 비가 크지 않지만, 갑자기 더워질 수 있어요. 얇은 아우터 대신 접어 넣기 쉬운 가디건은 어때요?';
    if (input.contains('미팅') || input.contains('회사'))
      return '미팅이라면 셔츠와 슬랙스 조합이 가장 안정적이에요. 오래 걸어야 한다면 로퍼 대신 낮은 굽의 신발로 바꿔볼까요?';
    if (input.contains('화사') || input.contains('밝'))
      return '좋아! 블랙 슬랙스는 유지하고, 아이보리 셔츠에 포인트 컬러 가방을 더하면 화사하게 보여요.';
    return '좋아, 그 조건을 반영해서 다시 골라봤어요. 오늘은 덥고 외부 이동이 있으니 가볍고 활동하기 편한 조합을 추천할게요.';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: Stack(children: [
        Positioned(
          left: 20,
          right: 20,
          top: 42,
          height: 59,
          child: Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line))),
            child: Row(children: [
              SizedBox(
                width: 48,
                height: 45,
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 62,
                  maxWidth: 62,
                  minHeight: 62,
                  maxHeight: 62,
                  child: Transform.translate(
                      offset: Offset(-9, 0), child: _ChatbotAvatar(size: 62)),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('착착 메이트',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('지금 코디를 같이 골라봐요',
                        style:
                            TextStyle(fontSize: 10, color: Color(0xFF71807D))),
                  ]),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _menuOpen = !_menuOpen),
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                        child: Text('•••',
                            style: TextStyle(
                                color: Color(0xFF83908B),
                                fontWeight: FontWeight.w800)))),
              ),
            ]),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          top: 101,
          bottom: 102,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 150),
            itemCount: lines.length + 1,
            itemBuilder: (context, index) {
              if (index == lines.length) {
                return MateOutfitSuggestion(
                  items: selectedGarments,
                  onUseOutfit: selectedGarments.length < 2
                      ? null
                      : () {
                          final onUseOutfit = widget.onUseOutfit;
                          if (onUseOutfit != null) {
                            onUseOutfit(List<GarmentItem>.unmodifiable(
                                selectedGarments));
                          } else {
                            Navigator.of(context).maybePop(
                                List<GarmentItem>.unmodifiable(
                                    selectedGarments));
                          }
                        },
                );
              }
              return ChatBubble(line: lines[index]);
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 56,
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              const prompts = [
                '오늘 뭐 입지?',
                '조금 더 화사하게',
                '비 올 때 괜찮아?',
                '미팅에 맞춰줘'
              ];
              final value = prompts[index];
              return GestureDetector(
                onTap: _isReplying ? null : () => _send(value),
                child: Container(
                  height: 34,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(99)),
                  child: Text(value, style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 50,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.line))),
            child: Row(children: [
              Expanded(
                child: Container(
                  height: 35,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(99)),
                  alignment: Alignment.center,
                  child: TextField(
                    controller: textController,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '메이트에게 물어보기',
                      hintStyle:
                          TextStyle(fontSize: 12, color: Color(0xFF7A8581)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isReplying ? null : _send,
                child: Container(
                  width: 35,
                  height: 35,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.mint, shape: BoxShape.circle),
                  child: const Text('↑',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            ]),
          ),
        ),
        const Positioned(left: 26, right: 26, top: 10, child: _PhoneTopBar()),
        if (_menuOpen)
          Positioned(
            right: 20,
            top: 86,
            width: 136,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const []),
              child: Column(children: [
                _ChatMenuAction(
                    label: '대화 초기화',
                    onTap: () {
                      setState(() => _menuOpen = false);
                      _resetChat();
                    }),
                _ChatMenuAction(
                    label: '대화 나가기',
                    color: const Color(0xFFA85B4E),
                    onTap: () {
                      setState(() => _menuOpen = false);
                      _exitChat();
                    }),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _ChatMenuAction extends StatelessWidget {
  const _ChatMenuAction(
      {required this.label, required this.onTap, this.color = AppColors.ink});
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 42,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Text(label, style: TextStyle(fontSize: 12, color: color)),
            ),
          ),
        ),
      );
}

class ChatLine {
  const ChatLine({required this.text, required this.mine});
  factory ChatLine.mate(String text) => ChatLine(text: text, mine: false);
  factory ChatLine.user(String text) => ChatLine(text: text, mine: true);
  final String text;
  final bool mine;
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.line});
  final ChatLine line;
  @override
  Widget build(BuildContext context) => Align(
      alignment: line.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!line.mine)
                  SizedBox(
                    width: 35,
                    height: 48,
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: 48,
                      maxWidth: 48,
                      minHeight: 48,
                      maxHeight: 48,
                      child: Transform.translate(
                          offset: Offset(-8, 0),
                          child: _ChatbotAvatar(size: 48)),
                    ),
                  ),
                if (!line.mine) const SizedBox(width: 7),
                Flexible(
                    child: Container(
                        constraints: const BoxConstraints(maxWidth: 255),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 11),
                        decoration: BoxDecoration(
                            color: line.mine ? AppColors.ink : AppColors.mist,
                            borderRadius: BorderRadius.circular(16).copyWith(
                                bottomLeft: line.mine
                                    ? const Radius.circular(16)
                                    : const Radius.circular(4),
                                bottomRight: line.mine
                                    ? const Radius.circular(4)
                                    : const Radius.circular(16))),
                        child: Text(line.text,
                            style: TextStyle(
                                color: line.mine ? Colors.white : AppColors.ink,
                                fontSize: 13,
                                height: 1.5))))
              ])));
}

class _ChatbotAvatar extends StatelessWidget {
  const _ChatbotAvatar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Image.asset('assets/characters/chakchak-chatbot.png',
            fit: BoxFit.contain,
            alignment: Alignment.center,
            semanticLabel: '착착 챗봇 메이트'),
      );
}

class MateOutfitSuggestion extends StatelessWidget {
  const MateOutfitSuggestion({
    super.key,
    required this.items,
    this.onUseOutfit,
  });
  final List<GarmentItem> items;
  final VoidCallback? onUseOutfit;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(left: 38, bottom: 15),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('이 조합은 어때요?',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 9),
        Row(children: [
          for (final item in items.take(3))
            Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                    width: 65,
                    height: 61,
                    child: GarmentVisual(item: item, size: 65, radius: 11)))
        ]),
        const SizedBox(height: 9),
        const Text('더운 날씨 + 외부 미팅',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.mintDark,
                fontWeight: FontWeight.w700)),
        if (onUseOutfit != null) ...[
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('mate-use-outfit-button'),
              onPressed: onUseOutfit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.mint,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChakchakRadii.control),
                ),
              ),
              child: const Text('오늘의 코디로 보기'),
            ),
          ),
        ],
      ]));
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.onDeleteAccount,
    this.accountDisplayName,
    this.accountEmail,
    this.accountPhotoUrl,
    this.initialHeight,
    this.initialWeight,
    this.initialGender,
  });
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final String? accountDisplayName;
  final String? accountEmail;
  final String? accountPhotoUrl;
  final int? initialHeight;
  final int? initialWeight;
  final String? initialGender;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String displayName;
  late String email;
  Uint8List? profilePhotoBytes;
  late int height;
  late int weight;
  late String gender;
  String region = '서울';
  bool calendarConnected = true;
  bool morningNotification = true;
  Set<String> styles = {'미니멀', '캐주얼'};

  @override
  void initState() {
    super.initState();
    height = widget.initialHeight ?? 165;
    weight = widget.initialWeight ?? 55;
    gender = widget.initialGender == '남' ? '남' : '여';
    email = widget.accountEmail?.trim() ?? '';
    final googleName = widget.accountDisplayName?.trim() ?? '';
    displayName = googleName.isNotEmpty
        ? googleName
        : email.isNotEmpty
            ? email.split('@').first
            : '사용자';
  }

  Future<void> _pickProfilePhoto() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 86,
        maxWidth: 900,
        maxHeight: 900);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => profilePhotoBytes = bytes);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('프로필 사진을 저장했어요.'), duration: Duration(seconds: 1)));
  }

  Future<void> _editAccount() async {
    final nameController = TextEditingController(text: displayName);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            22, 0, 22, MediaQuery.viewInsetsOf(sheetContext).bottom + 28),
        child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('내 정보 수정', style: ChakchakTypography.section),
              const SizedBox(height: 8),
              Text('착착에 표시되는 이름과 Google 계정 정보를 관리해요.',
                  style: ChakchakTypography.label.copyWith(
                      color: ChakchakColors.textDisabled, height: 1.4)),
              const SizedBox(height: 20),
              TextField(
                  controller: nameController,
                  style: ChakchakTypography.label,
                  decoration: const InputDecoration(
                      labelText: '이름', filled: true, fillColor: Colors.white)),
              const SizedBox(height: 12),
              TextFormField(
                  initialValue: email,
                  readOnly: true,
                  style: ChakchakTypography.label,
                  decoration: const InputDecoration(
                      labelText: '이메일', filled: true, fillColor: Colors.white)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    setState(() => displayName = name);
                    Navigator.of(sheetContext).pop();
                  },
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('내 정보 저장')),
              const Divider(height: 40),
              const Text('로그인 및 보안', style: ChakchakTypography.card),
              const SizedBox(height: 8),
              Text('Google 로그인 비밀번호는 Google에서 관리됩니다.',
                  style: ChakchakTypography.label.copyWith(
                      color: ChakchakColors.textDisabled, height: 1.4)),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(
                        text: 'https://myaccount.google.com/security'));
                    if (sheetContext.mounted)
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                              content: Text('Google 보안 설정 주소를 복사했어요.')));
                  },
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('Google 비밀번호 변경 주소 복사')),
              const Divider(height: 40),
              const Text('개인정보', style: ChakchakTypography.card),
              const SizedBox(height: 8),
              Text('착착이 처리하는 정보와 이용 목적, 보관 및 삭제 기준을 확인할 수 있어요.',
                  style: ChakchakTypography.label.copyWith(
                      color: ChakchakColors.textDisabled, height: 1.4)),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: _showPrivacyPolicy,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('개인정보 처리방침 보기')),
              const Divider(height: 40),
              const Text('회원 탈퇴',
                  style: TextStyle(
                      fontFamily: 'Paperlogy',
                      fontSize: 18,
                      height: 1,
                      color: Color(0xFFB45142),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('계정과 옷장·일정·맞춤 설정이 모두 삭제되고 재가입 시 온보딩부터 시작합니다.',
                  style: ChakchakTypography.label.copyWith(
                      color: ChakchakColors.textDisabled, height: 1.4)),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _deleteAccount();
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC65D4A),
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('착착 회원 탈퇴')),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48)),
                  child: const Text('취소')),
            ])),
      ),
    );
    nameController.dispose();
  }

  Future<void> _deleteAccount() async {
    final confirmationController = TextEditingController();
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('정말 탈퇴할까요?'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('계정과 데이터를 삭제하면 복구할 수 없습니다. 계속하려면 탈퇴를 입력해주세요.'),
                    const SizedBox(height: 14),
                    TextField(
                        controller: confirmationController,
                        style: ChakchakTypography.label,
                        decoration: const InputDecoration(
                            labelText: '확인 문구',
                            hintText: '탈퇴',
                            filled: true,
                            fillColor: Colors.white))
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소')),
                FilledButton(
                    onPressed: () => Navigator.of(dialogContext)
                        .pop(confirmationController.text.trim() == '탈퇴'),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD96655)),
                    child: const Text('계정과 데이터 삭제'))
              ],
            ));
    confirmationController.dispose();
    if (confirmed == true) {
      try {
        await widget.onDeleteAccount();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('보안을 위해 Google 재로그인 후 다시 탈퇴해주세요.'),
        ));
      }
    }
  }

  Future<void> _showPrivacyPolicy() => showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('개인정보 처리방침'),
          content: const SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('수집 항목', style: ChakchakTypography.card),
                SizedBox(height: 8),
                Text(
                    'Google 계정의 이름·이메일·프로필 사진과 사용자가 입력한 신체 정보·옷장·일정·선호 스타일을 처리합니다.'),
                SizedBox(height: 16),
                Text('이용 목적', style: ChakchakTypography.card),
                SizedBox(height: 8),
                Text('로그인, 개인화된 코디 추천과 사용자 설정 유지 목적으로 이용합니다.'),
                SizedBox(height: 16),
                Text('보관 및 삭제', style: ChakchakTypography.card),
                SizedBox(height: 8),
                Text('로컬 데이터는 이 기기에 저장되며 회원 탈퇴 시 계정과 착착 데이터를 삭제합니다.'),
                SizedBox(height: 16),
                Text('외부 서비스', style: ChakchakTypography.card),
                SizedBox(height: 8),
                Text(
                    'Google 로그인과 선택 시 Google Calendar, 날씨 확인을 위한 외부 서비스를 이용합니다.'),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('확인'))
          ],
        ),
      );

  Future<void> _editBodyProfile() async {
    final heightController = TextEditingController(text: '$height');
    final weightController = TextEditingController(text: '$weight');
    var temporaryGender = gender;
    final result =
        await showModalBottomSheet<({int height, int weight, String gender})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
                padding: EdgeInsets.fromLTRB(
                    22, 0, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('나의 신체 프로필',
                          style: ChakchakTypography.section),
                      const SizedBox(height: 8),
                      Text('핏 추천에만 사용하며 다른 사용자에게 공개하지 않아요.',
                          style: ChakchakTypography.label.copyWith(
                              color: ChakchakColors.textDisabled, height: 1.4)),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: TextField(
                                controller: heightController,
                                keyboardType: TextInputType.number,
                                style: ChakchakTypography.label,
                                decoration: const InputDecoration(
                                    labelText: '키',
                                    suffixText: 'cm',
                                    filled: true,
                                    fillColor: Colors.white))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: TextField(
                                controller: weightController,
                                keyboardType: TextInputType.number,
                                style: ChakchakTypography.label,
                                decoration: const InputDecoration(
                                    labelText: '몸무게',
                                    suffixText: 'kg',
                                    filled: true,
                                    fillColor: Colors.white))),
                      ]),
                      const SizedBox(height: 17),
                      const Text('성별', style: ChakchakTypography.bodyStrong),
                      const SizedBox(height: 8),
                      Row(children: [
                        for (final value in ['남', '여']) ...[
                          Expanded(
                            child: ChoiceChip(
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(value, textAlign: TextAlign.center),
                              ),
                              selected: temporaryGender == value,
                              onSelected: (_) =>
                                  setSheetState(() => temporaryGender = value),
                            ),
                          ),
                          if (value == '남') const SizedBox(width: 8),
                        ],
                      ]),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          final nextHeight =
                              int.tryParse(heightController.text);
                          final nextWeight =
                              int.tryParse(weightController.text);
                          if (nextHeight == null ||
                              nextWeight == null ||
                              nextHeight < 120 ||
                              nextHeight > 220 ||
                              nextWeight < 30 ||
                              nextWeight > 200) return;
                          Navigator.of(context).pop((
                            height: nextHeight,
                            weight: nextWeight,
                            gender: temporaryGender
                          ));
                        },
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48)),
                        child: const Text('저장하기'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48)),
                          child: const Text('취소')),
                    ])),
              )),
    );
    heightController.dispose();
    weightController.dispose();
    if (result != null && mounted)
      setState(() {
        height = result.height;
        weight = result.weight;
        gender = result.gender;
      });
  }

  Future<void> _pickRegion() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      barrierColor: const Color(0x66192420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => _WeatherRegionSheet(selectedRegion: region),
    );
    if (result == null || !mounted) return;
    setState(() => region =
        result == _WeatherRegionSheet.currentLocationValue ? '내 위치' : result);
  }

  Future<void> _pickStyles() async {
    var temporary = Set<String>.of(styles);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      barrierColor: const Color(0x66192420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ProfilePreferenceSheetHeader(
                  title: '선호 스타일',
                  description: '여러 개를 골라도 괜찮아요. 나중에 바꿀 수 있어요.',
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['미니멀', '캐주얼', '페미닌', '모던', '스트릿', '클래식']
                      .map((item) => _OnboardingChip(
                            label: item,
                            selected: temporary.contains(item),
                            onTap: () => setSheetState(() =>
                                temporary.contains(item)
                                    ? temporary.remove(item)
                                    : temporary.add(item)),
                          ))
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: temporary.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(temporary),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mint,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD8DEDC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('선택 저장'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) setState(() => styles = result);
  }

  Future<void> _toggleCalendar() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Google Calendar'),
              content: Text(calendarConnected
                  ? '캘린더 연결을 해제할까요? 옷장과 직접 입력한 일정은 유지돼요.'
                  : '오늘 일정의 제목과 시간을 읽도록 연결할까요? 로그인 권한과는 별도예요.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('취소')),
                FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(calendarConnected ? '연결 해제' : '연결'))
              ],
            ));
    if (confirmed == true && mounted)
      setState(() => calendarConnected = !calendarConnected);
  }

  Future<void> _resetPreferences() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('맞춤 설정을 초기화할까요?'),
              content:
                  const Text('신체 프로필과 추천 설정만 기본값으로 돌아가며 계정과 프로필 사진은 유지돼요.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('취소')),
                FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('초기화'))
              ],
            ));
    if (confirmed == true && mounted) {
      setState(() {
        height = 165;
        weight = 55;
        gender = '여';
        region = '서울';
        calendarConnected = true;
        morningNotification = true;
        styles = {'미니멀', '캐주얼'};
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('맞춤 설정을 초기화했어요.'), duration: Duration(seconds: 1)));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('로그아웃할까요?'),
                content: const Text('옷장과 맞춤 설정은 그대로 유지돼요.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소')),
                  FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('로그아웃'))
                ]));
    if (confirmed == true) await widget.onLogout();
  }

  void _toggleNotification() {
    setState(() => morningNotification = !morningNotification);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(morningNotification ? '아침 코디 알림을 켰어요.' : '아침 코디 알림을 껐어요.'),
        duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        ListView(
            padding: const EdgeInsets.fromLTRB(20, 42, 20, 120),
            children: [
              const Text('마이페이지', style: ChakchakTypography.section),
              const SizedBox(height: 20),
              Container(
                  key: const Key('profile-summary-card'),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: ChakchakColors.surface,
                      border: Border.all(color: ChakchakColors.borderDefault),
                      borderRadius: BorderRadius.circular(ChakchakRadii.card)),
                  child: Row(children: [
                    Semantics(
                        button: true,
                        label: profilePhotoBytes == null
                            ? '프로필 사진 등록'
                            : '프로필 사진 변경',
                        child: InkWell(
                            onTap: _pickProfilePhoto,
                            borderRadius: BorderRadius.circular(32),
                            child: Stack(clipBehavior: Clip.none, children: [
                              CircleAvatar(
                                  radius: 28,
                                  backgroundColor: ChakchakColors.brandSubtle,
                                  backgroundImage: profilePhotoBytes == null
                                      ? (widget.accountPhotoUrl?.isNotEmpty ==
                                              true
                                          ? NetworkImage(
                                              widget.accountPhotoUrl!)
                                          : null)
                                      : MemoryImage(profilePhotoBytes!),
                                  child: profilePhotoBytes == null &&
                                          widget.accountPhotoUrl?.isNotEmpty !=
                                              true
                                      ? Text(
                                          displayName.isEmpty
                                              ? '착'
                                              : displayName.substring(0, 1),
                                          style: ChakchakTypography.card
                                              .copyWith(
                                                  color: AppColors.mintDark))
                                      : null),
                              Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                          color: AppColors.mint,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2)),
                                      child: const Icon(Icons.add_rounded,
                                          size: 16, color: Colors.white)))
                            ]))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$displayName님',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChakchakTypography.card),
                            const SizedBox(height: 8),
                            Text(email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ChakchakTypography.label.copyWith(
                                    color: ChakchakColors.textDisabled))
                          ]),
                    )
                  ])),
              const SizedBox(height: 16),
              Container(
                key: const Key('body-profile-card'),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: ChakchakColors.surface,
                    border: Border.all(color: ChakchakColors.borderDefault),
                    borderRadius: BorderRadius.circular(ChakchakRadii.card)),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('나의 신체 프로필',
                              style: ChakchakTypography.card),
                          const SizedBox(height: 8),
                          Text('핏 추천에만 사용해요.',
                              style: ChakchakTypography.label
                                  .copyWith(color: ChakchakColors.textDisabled))
                        ])),
                    TextButton(
                        onPressed: _editBodyProfile, child: const Text('수정하기'))
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _BodyStat(label: '키', value: '$height cm')),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _BodyStat(label: '몸무게', value: '$weight kg')),
                    const SizedBox(width: 8),
                    Expanded(child: _BodyStat(label: '성별', value: gender))
                  ]),
                ]),
              ),
              const SizedBox(height: 30),
              _SettingGroup(title: '추천 설정', children: [
                _SettingRow(label: '날씨 지역', value: region, onTap: _pickRegion),
                _SettingRow(
                    label: '선호 스타일',
                    value: styles.join(' · '),
                    onTap: _pickStyles),
                _ToggleSettingRow(
                    label: 'Google Calendar',
                    value: calendarConnected,
                    onChanged: (value) =>
                        setState(() => calendarConnected = value)),
                _ToggleSettingRow(
                    label: '아침 코디 알림',
                    value: morningNotification,
                    onChanged: (value) =>
                        setState(() => morningNotification = value)),
              ]),
              const SizedBox(height: 30),
              _SettingGroup(title: '계정', children: [
                _SettingRow(label: '내 정보 수정', value: '', onTap: _editAccount),
              ]),
              const SizedBox(height: 30),
              OutlinedButton(
                  onPressed: _resetPreferences,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: const Color(0xFF66736F),
                      side: const BorderSide(color: AppColors.line)),
                  child: const Text('맞춤 설정 초기화')),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: const Color(0xFFA85B4E),
                      side: const BorderSide(color: Color(0xFFEADFDC))),
                  child: const Text('로그아웃')),
            ]),
        const Positioned(left: 26, right: 26, top: 10, child: _PhoneTopBar()),
      ]);
}

class _ProfilePreferenceSheetHeader extends StatelessWidget {
  const _ProfilePreferenceSheetHeader({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ChakchakTypography.section,
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: ChakchakTypography.label.copyWith(
                    color: ChakchakColors.textDisabled,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F3F2),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '×',
                style: TextStyle(
                  color: Color(0xFF76817D),
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
}

class _BodyStat extends StatelessWidget {
  const _BodyStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
          color: ChakchakColors.brandSubtle,
          borderRadius: BorderRadius.circular(ChakchakRadii.control)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: ChakchakTypography.caption
                .copyWith(color: ChakchakColors.textDisabled)),
        const SizedBox(height: 8),
        Row(children: [
          if (color != null) ...[
            CircleAvatar(radius: 6, backgroundColor: color),
            const SizedBox(width: 5)
          ],
          Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ChakchakTypography.labelStrong))
        ])
      ]));
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final separated = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        separated.add(
            const Divider(height: 1, indent: 16, endIndent: 16, thickness: 1));
      }
      separated.add(children[index]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: ChakchakTypography.card),
      const SizedBox(height: 12),
      Material(
          color: ChakchakColors.surface,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: ChakchakColors.borderDefault),
            borderRadius: BorderRadius.circular(ChakchakRadii.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: separated))
    ]);
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(
      {required this.label, required this.value, required this.onTap});
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(child: Text(label, style: ChakchakTypography.bodyStrong)),
            if (value.isNotEmpty)
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: ChakchakTypography.label
                          .copyWith(color: ChakchakColors.textDisabled))),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 24, color: ChakchakColors.textDisabled)
          ]),
        ),
      ));
}

class _ToggleSettingRow extends StatelessWidget {
  const _ToggleSettingRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Expanded(child: Text(label, style: ChakchakTypography.bodyStrong)),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.mintDark,
            ),
          ]),
        ),
      );
}

class TodaySchedule {
  const TodaySchedule(
      {required this.id, required this.time, required this.title, this.date});
  final int id;
  final String time;
  final String title;
  final DateTime? date;

  DateTime get effectiveDate => DateUtils.dateOnly(date ?? DateTime.now());

  bool isOn(DateTime target) =>
      DateUtils.isSameDay(effectiveDate, DateUtils.dateOnly(target));

  Map<String, Object?> toJson() => {
        'id': id,
        'time': time,
        'title': title,
        'date': effectiveDate.toIso8601String(),
      };

  factory TodaySchedule.fromJson(Map<String, dynamic> json) => TodaySchedule(
        id: (json['id'] as num?)?.toInt() ??
            DateTime.now().microsecondsSinceEpoch,
        time: json['time'] as String? ?? '09:00',
        title: json['title'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? ''),
      );
}

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet(
      {super.key,
      required this.initialSchedules,
      required this.onChanged,
      this.onImportGoogleCalendar});
  final List<TodaySchedule> initialSchedules;
  final ValueChanged<List<TodaySchedule>> onChanged;
  final Future<List<TodaySchedule>> Function(DateTime date)?
      onImportGoogleCalendar;

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  late final List<TodaySchedule> schedules;
  final titleController = TextEditingController();
  TimeOfDay selectedTime = const TimeOfDay(hour: 15, minute: 0);
  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());
  bool _calendarLoading = false;

  List<TodaySchedule> get _selectedSchedules =>
      schedules.where((item) => item.isOn(selectedDate)).toList(growable: false)
        ..sort((a, b) => a.time.compareTo(b.time));

  @override
  void initState() {
    super.initState();
    schedules = List.of(widget.initialSchedules)..sort(_compareSchedules);
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static int _compareSchedules(TodaySchedule a, TodaySchedule b) {
    final dateCompare = a.effectiveDate.compareTo(b.effectiveDate);
    return dateCompare != 0 ? dateCompare : a.time.compareTo(b.time);
  }

  String _formatDate(DateTime date) =>
      '${date.month}월 ${date.day}일 ${_weekdayLabel(date.weekday)}';

  String _weekdayLabel(int weekday) =>
      const ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'][weekday - 1];

  void _addSchedule(String title, {String? time}) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    setState(() {
      schedules.add(TodaySchedule(
          id: DateTime.now().microsecondsSinceEpoch,
          time: time ?? _formatTime(selectedTime),
          title: cleanTitle,
          date: selectedDate));
      schedules.sort(_compareSchedules);
    });
    titleController.clear();
  }

  void _removeSchedule(int id) {
    setState(() => schedules.removeWhere((item) => item.id == id));
  }

  void _saveSchedules() {
    widget.onChanged(List.unmodifiable(schedules));
    Navigator.of(context).pop();
  }

  Future<void> _importGoogleCalendar() async {
    final importer = widget.onImportGoogleCalendar;
    if (importer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Google 계정으로 로그인한 뒤 Calendar를 연결해주세요.'),
      ));
      return;
    }
    if (_calendarLoading) return;
    setState(() => _calendarLoading = true);
    try {
      final imported = await importer(selectedDate);
      if (!mounted) return;
      var addedCount = 0;
      setState(() {
        for (final item in imported) {
          final duplicated = schedules.any((existing) =>
              existing.isOn(item.effectiveDate) &&
              existing.time == item.time &&
              existing.title == item.title);
          if (!duplicated) {
            schedules.add(item);
            addedCount += 1;
          }
        }
        schedules.sort(_compareSchedules);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(imported.isEmpty
            ? '${_formatDate(selectedDate)}에는 Google Calendar 일정이 없어요.'
            : addedCount == 0
                ? '이미 가져온 일정이에요.'
                : 'Google Calendar 일정 $addedCount개를 가져왔어요.'),
      ));
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Bad state: ', '');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _calendarLoading = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: selectedTime, helpText: '일정 시간 선택');
    if (picked != null && mounted) setState(() => selectedTime = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      helpText: '일정을 확인할 날짜 선택',
    );
    if (picked != null && mounted) {
      setState(() => selectedDate = DateUtils.dateOnly(picked));
    }
  }

  void _moveDate(int days) {
    setState(() => selectedDate = selectedDate.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .84,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('일정 관리', style: ChakchakTypography.section),
                    SizedBox(height: 5),
                    Text('날짜를 선택해 일정을 확인하고 추가할 수 있어요.',
                        style: TextStyle(
                            fontSize: AppA11y.captionSize,
                            color: AppColors.muted))
                  ])),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: Color(0xFFF0F3F2), shape: BoxShape.circle),
                  child: const Text('×',
                      style: TextStyle(
                          color: Color(0xFF76817D),
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF2F7F5),
                            border: Border.all(color: const Color(0xFFCFE3DD)),
                            borderRadius: BorderRadius.circular(15)),
                        child: Row(children: [
                          IconButton(
                              onPressed: () => _moveDate(-1),
                              tooltip: '이전 날짜',
                              icon: const Icon(Icons.chevron_left_rounded,
                                  color: AppColors.ink)),
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.calendar_month_outlined,
                                        size: 20, color: AppColors.mintDark),
                                    const SizedBox(width: 8),
                                    Text(_formatDate(selectedDate),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800)),
                                  ]),
                            ),
                          ),
                          IconButton(
                              onPressed: () => _moveDate(1),
                              tooltip: '다음 날짜',
                              icon: const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.ink)),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        const Text('선택한 날짜의 일정',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${_selectedSchedules.length}개',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mintDark,
                                fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 10),
                      if (_selectedSchedules.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.line),
                              borderRadius: BorderRadius.circular(15)),
                          child: Text(
                              '${_formatDate(selectedDate)}에는 등록된 일정이 없어요.',
                              style: TextStyle(
                                  fontSize: AppA11y.captionSize,
                                  color: AppColors.muted)),
                        )
                      else
                        for (final item in _selectedSchedules) ...[
                          Container(
                            height: 48,
                            padding: const EdgeInsets.only(left: 16, right: 7),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(15)),
                            child: Row(children: [
                              SizedBox(
                                  width: 54,
                                  child: Text(item.time,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.mintDark,
                                          fontWeight: FontWeight.w800))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700))),
                              IconButton(
                                  onPressed: () => _removeSchedule(item.id),
                                  tooltip: '${item.title} 삭제',
                                  icon: const Icon(Icons.close_rounded,
                                      size: 19, color: Color(0xFF8A9490))),
                            ]),
                          ),
                          const SizedBox(height: 8),
                        ],
                      const SizedBox(height: 22),
                      Text('${_formatDate(selectedDate)}에 일정 추가',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Row(children: [
                        OutlinedButton(
                            onPressed: _pickTime,
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(82, 48),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                foregroundColor: AppColors.ink,
                                side: const BorderSide(color: AppColors.line),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppRadius.control))),
                            child: Text(_formatTime(selectedTime),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextField(
                                controller: titleController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: _addSchedule,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                    hintText: '예: 성수동 전시 관람',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.control),
                                        borderSide: const BorderSide(
                                            color: AppColors.line)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.control),
                                        borderSide: const BorderSide(
                                            color: AppColors.mintDark))))),
                        const SizedBox(width: 8),
                        IconButton(
                            onPressed: () => _addSchedule(titleController.text),
                            tooltip: '일정 추가',
                            icon: const Icon(Icons.add_rounded),
                            style: IconButton.styleFrom(
                                minimumSize: const Size(48, 48),
                                backgroundColor: AppColors.mint,
                                foregroundColor: Colors.white)),
                      ]),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                          onPressed:
                              _calendarLoading ? null : _importGoogleCalendar,
                          icon: _calendarLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.mintDark))
                              : const Icon(Icons.calendar_month_outlined,
                                  size: 20),
                          label: Text(_calendarLoading
                              ? 'Google Calendar 불러오는 중'
                              : '${_formatDate(selectedDate)} Google Calendar 가져오기'),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: AppColors.ink,
                              side: const BorderSide(color: AppColors.line),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)))),
                      const SizedBox(height: 8),
                    ]),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
                onPressed: _saveSchedules,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.mint,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('일정 저장하기',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
          ]),
        ),
      ),
    );
  }
}

class ReDiscoveryRow extends StatelessWidget {
  const ReDiscoveryRow(
      {super.key, required this.garments, this.records = const []});
  final List<GarmentItem> garments;
  final List<SavedOutfitRecord> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final lastYear = now.year - 1;
    final lastYearCount = records
        .where((record) =>
            record.date.year == lastYear && record.date.month == now.month)
        .length;
    return Column(children: [
      _DiscoveryCard(
          color: const Color(0xFFE4DCF8),
          asset: 'assets/characters/chakchak-last-year.png',
          title: '작년 이맘때 입었던 코디',
          subtitle: '${now.month}월의 기록 $lastYearCount개',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DiscoveryScreen(
                  garments: garments, records: records, initialTab: 0)))),
      const SizedBox(height: 12),
      _DiscoveryCard(
          color: const Color(0xFFFBE3B5),
          asset: 'assets/characters/chakchak-long-unworn.png',
          title: '오랫동안 안 입은 옷',
          subtitle: '새롭게 조합해볼까요?',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DiscoveryScreen(
                  garments: garments, records: records, initialTab: 1)))),
    ]);
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard(
      {required this.color,
      required this.asset,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final Color color;
  final String asset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: double.infinity,
            height: 122,
            child: Stack(children: [
              const Positioned(
                  right: -18, top: 18, child: _DiscoveryCloud(scale: 1)),
              const Positioned(
                  left: -24, top: 64, child: _DiscoveryCloud(scale: .7)),
              Positioned(
                  right: 4,
                  top: 0,
                  child: IgnorePointer(
                      child: Image.asset(asset,
                          width: 118, height: 122, fit: BoxFit.contain))),
              Positioned(
                  left: 16,
                  right: 124,
                  top: 0,
                  bottom: 0,
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    height: 1.2)),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: const TextStyle(
                                    fontSize: AppA11y.captionSize,
                                    color: Color(0xFF535C59)))
                          ]))),
            ]),
          ),
        ),
      );
}

class _DiscoveryCloud extends StatelessWidget {
  const _DiscoveryCloud({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) => Transform.scale(
        scale: scale,
        child: SizedBox(
          width: 72,
          height: 38,
          child: Stack(children: [
            Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(99)))),
            Positioned(
                left: 14,
                top: 1,
                child: Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .55),
                        shape: BoxShape.circle))),
            Positioned(
                right: 11,
                top: 8,
                child: Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .55),
                        shape: BoxShape.circle))),
          ]),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
      {super.key, required this.title, this.trailing, this.onTap});
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title, style: ChakchakTypography.section),
        if (trailing != null) ...[
          const Spacer(),
          TextButton(
              onPressed: onTap,
              child: Row(children: [
                Text(trailing!,
                    style: const TextStyle(
                        fontSize: AppA11y.captionSize, color: AppColors.muted)),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.muted)
              ]))
        ]
      ]);
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.color = AppColors.ink});
  final Color color;
  @override
  Widget build(BuildContext context) => Text('착착',
      style: TextStyle(
          fontFamily: 'Paperlogy',
          color: color,
          fontSize: 30,
          height: 1,
          fontWeight: FontWeight.w800));
}

class _Pill extends StatelessWidget {
  const _Pill(
      {required this.label,
      required this.color,
      this.foreground = Colors.white});
  final String label;
  final Color color;
  final Color foreground;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: AppA11y.captionSize,
              fontWeight: FontWeight.w800,
              color: foreground)));
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20, this.markKey});

  final double size;
  final Key? markKey;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/icons/g-logo.png',
        key: markKey ?? const ValueKey('google-brand-mark'),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      );
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow(
      {required this.value,
      required this.label,
      required this.onChanged,
      required this.onOpen});
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox.square(
              dimension: AppA11y.touchTarget,
              child: Checkbox(
                  value: value,
                  onChanged: (next) => onChanged(next ?? false),
                  activeColor: AppColors.mintDark)),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('[필수] ',
                    style: TextStyle(
                        fontSize: AppA11y.metadataSize,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mintDark)),
                TextButton(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(
                            AppA11y.touchTarget, AppA11y.touchTarget)),
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: AppA11y.metadataSize,
                            decoration: TextDecoration.underline))),
                const Text('에 동의합니다.',
                    style: TextStyle(
                        fontSize: AppA11y.metadataSize,
                        color: AppColors.muted)),
              ],
            ),
          ),
        ],
      );
}

enum MateMood { sunny, thinking, excited }

class MateAvatar extends StatelessWidget {
  const MateAvatar({super.key, required this.size, required this.mood});
  final double size;
  final MateMood mood;

  @override
  Widget build(BuildContext context) {
    final asset = switch (mood) {
      MateMood.sunny => 'assets/characters/chakchak-picnic.png',
      MateMood.thinking => 'assets/characters/chakchak-study.png',
      MateMood.excited => 'assets/characters/chakchak-date.png',
    };
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        semanticLabel: '착착 코디 메이트',
      ),
    );
  }
}

const garmentCategoryDetails = <String, List<String>>{
  '상의': ['반팔티', '긴팔티', '민소매', '셔츠', '데님 셔츠', '후드티', '후드 집업'],
  '하의': [
    '스트레이트 팬츠',
    '와이드 슬랙스',
    '스트레이트 데님',
    '카고 팬츠',
    '조거 팬츠',
    '기본 반바지',
    '버뮤다 팬츠'
  ],
  '아우터': [
    '블레이저',
    '가디건',
    '롱 코트',
    '숏 코트',
    '롱 트렌치',
    '롱 패딩',
    '숏 패딩',
    '패딩 조끼',
    '크롭 데님 재킷',
    '봄버 재킷',
    '바람막이'
  ],
  '원피스': ['A라인 미디 원피스'],
  '신발': ['로퍼', '러닝화', '하이탑 스니커즈', '로우탑 스니커즈'],
  '액세서리': ['가방', '모자', '벨트', '주얼리', '기타'],
};

class GarmentColorOption {
  const GarmentColorOption(this.name, this.color, {this.useLightCheck = false});

  final String name;
  final Color color;
  final bool useLightCheck;
}

const garmentColorOptions = <GarmentColorOption>[
  GarmentColorOption('화이트', Color(0xFFF6F5F1)),
  GarmentColorOption('아이보리', Color(0xFFF2E8D3)),
  GarmentColorOption('베이지', Color(0xFFD8BE98)),
  GarmentColorOption('브라운', Color(0xFF8B6247), useLightCheck: true),
  GarmentColorOption('그레이', Color(0xFF9A9EA1), useLightCheck: true),
  GarmentColorOption('블랙', Color(0xFF25292C), useLightCheck: true),
  GarmentColorOption('레드', Color(0xFFC94C51), useLightCheck: true),
  GarmentColorOption('핑크', Color(0xFFE7A8B5)),
  GarmentColorOption('그린', Color(0xFF668E6D), useLightCheck: true),
  GarmentColorOption('블루', Color(0xFF739BC2), useLightCheck: true),
  GarmentColorOption('네이비', Color(0xFF344A68), useLightCheck: true),
];

class GarmentSample {
  const GarmentSample({
    required this.name,
    required this.category,
    required this.detailCategory,
    required this.assetPath,
  });

  final String name;
  final String category;
  final String detailCategory;
  final String assetPath;
}

const garmentSamples = <GarmentSample>[
  GarmentSample(
      name: '베이직 반팔티',
      category: '상의',
      detailCategory: '반팔티',
      assetPath:
          'assets/garment_samples/unisex_tshirt_basic_shortsleeve.png.png'),
  GarmentSample(
      name: '베이직 긴팔티',
      category: '상의',
      detailCategory: '긴팔티',
      assetPath:
          'assets/garment_samples/unisex_tshirt_basic_longsleeve.png.png'),
  GarmentSample(
      name: '베이직 민소매',
      category: '상의',
      detailCategory: '민소매',
      assetPath:
          'assets/garment_samples/unisex_tanktop_basic_sleeveless.png.png'),
  GarmentSample(
      name: '베이직 셔츠',
      category: '상의',
      detailCategory: '셔츠',
      assetPath: 'assets/garment_samples/unisex_shirt_basic_longsleeve.png'),
  GarmentSample(
      name: '데님 셔츠',
      category: '상의',
      detailCategory: '데님 셔츠',
      assetPath: 'assets/garment_samples/unisex_shirt_denim_longsleeve.png'),
  GarmentSample(
      name: '베이직 후드티',
      category: '상의',
      detailCategory: '후드티',
      assetPath: 'assets/garment_samples/unisex_hoodie_basic.png.png'),
  GarmentSample(
      name: '후드 집업',
      category: '상의',
      detailCategory: '후드 집업',
      assetPath: 'assets/garment_samples/unisex_hoodie_zipup.png.png'),
  GarmentSample(
      name: '스트레이트 팬츠',
      category: '하의',
      detailCategory: '스트레이트 팬츠',
      assetPath: 'assets/garment_samples/unisex_pants_straight.png'),
  GarmentSample(
      name: '와이드 슬랙스',
      category: '하의',
      detailCategory: '와이드 슬랙스',
      assetPath: 'assets/garment_samples/unisex_slacks_wide.png'),
  GarmentSample(
      name: '스트레이트 데님',
      category: '하의',
      detailCategory: '스트레이트 데님',
      assetPath:
          'assets/garment_samples/unisex_jeans_straight_lightblue_denim.png'),
  GarmentSample(
      name: '카고 팬츠',
      category: '하의',
      detailCategory: '카고 팬츠',
      assetPath: 'assets/garment_samples/unisex_pants_cargo.png'),
  GarmentSample(
      name: '조거 팬츠',
      category: '하의',
      detailCategory: '조거 팬츠',
      assetPath: 'assets/garment_samples/unisex_pants_jogger.png'),
  GarmentSample(
      name: '기본 반바지',
      category: '하의',
      detailCategory: '기본 반바지',
      assetPath: 'assets/garment_samples/unisex_shorts_basic.png'),
  GarmentSample(
      name: '버뮤다 팬츠',
      category: '하의',
      detailCategory: '버뮤다 팬츠',
      assetPath: 'assets/garment_samples/unisex_shorts_bermuda.png'),
  GarmentSample(
      name: '싱글 블레이저',
      category: '아우터',
      detailCategory: '블레이저',
      assetPath: 'assets/garment_samples/unisex_blazer_single_basi.png'),
  GarmentSample(
      name: '베이직 가디건',
      category: '아우터',
      detailCategory: '가디건',
      assetPath: 'assets/garment_samples/unisex_cardigan_basic_longsleeve.png'),
  GarmentSample(
      name: '롱 코트',
      category: '아우터',
      detailCategory: '롱 코트',
      assetPath: 'assets/garment_samples/unisex_outer_coat_long.png'),
  GarmentSample(
      name: '숏 코트',
      category: '아우터',
      detailCategory: '숏 코트',
      assetPath: 'assets/garment_samples/unisex_outer_coat_short.png'),
  GarmentSample(
      name: '롱 트렌치코트',
      category: '아우터',
      detailCategory: '롱 트렌치',
      assetPath: 'assets/garment_samples/unisex_outer_trench_long.png'),
  GarmentSample(
      name: '롱 패딩',
      category: '아우터',
      detailCategory: '롱 패딩',
      assetPath: 'assets/garment_samples/unisex_outer_puffer_long.png'),
  GarmentSample(
      name: '숏 패딩',
      category: '아우터',
      detailCategory: '숏 패딩',
      assetPath: 'assets/garment_samples/unisex_outer_puffer_short.png'),
  GarmentSample(
      name: '패딩 조끼',
      category: '아우터',
      detailCategory: '패딩 조끼',
      assetPath: 'assets/garment_samples/unisex_outer_puffer_vest.png'),
  GarmentSample(
      name: '크롭 데님 재킷',
      category: '아우터',
      detailCategory: '크롭 데님 재킷',
      assetPath: 'assets/garment_samples/unisex_outer_denimjacket_cropped.png'),
  GarmentSample(
      name: '봄버 재킷',
      category: '아우터',
      detailCategory: '봄버 재킷',
      assetPath: 'assets/garment_samples/unisex_outer_bomber.png'),
  GarmentSample(
      name: '바람막이',
      category: '아우터',
      detailCategory: '바람막이',
      assetPath: 'assets/garment_samples/unisex_outer_windbreaker.png'),
  GarmentSample(
      name: 'A라인 미디 원피스',
      category: '원피스',
      detailCategory: 'A라인 미디 원피스',
      assetPath:
          'assets/garment_samples/female_dress_aline_longsleeve_midi.png'),
  GarmentSample(
      name: '클래식 로퍼',
      category: '신발',
      detailCategory: '로퍼',
      assetPath: 'assets/garment_samples/unisex_shoes_loafer_black.png'),
  GarmentSample(
      name: '러닝화',
      category: '신발',
      detailCategory: '러닝화',
      assetPath: 'assets/garment_samples/unisex_shoes_running.png'),
  GarmentSample(
      name: '하이탑 스니커즈',
      category: '신발',
      detailCategory: '하이탑 스니커즈',
      assetPath: 'assets/garment_samples/unisex_shoes_sneakers_hightop.png'),
  GarmentSample(
      name: '로우탑 스니커즈',
      category: '신발',
      detailCategory: '로우탑 스니커즈',
      assetPath: 'assets/garment_samples/unisex_shoes_sneakers_lowtop.png'),
];

class ColorizedGarmentAsset extends StatelessWidget {
  const ColorizedGarmentAsset({
    super.key,
    required this.assetPath,
    required this.color,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  });

  final String assetPath;
  final Color color;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final red = color.r;
    final green = color.g;
    final blue = color.b;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix([
        .2126 * red,
        .7152 * red,
        .0722 * red,
        0,
        0,
        .2126 * green,
        .7152 * green,
        .0722 * green,
        0,
        0,
        .2126 * blue,
        .7152 * blue,
        .0722 * blue,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: Image.asset(assetPath,
          width: double.infinity,
          height: double.infinity,
          fit: fit,
          semanticLabel: semanticLabel),
    );
  }
}

class GarmentItem {
  const GarmentItem(
      {required this.name,
      required this.category,
      required this.color,
      required this.location,
      required this.tone,
      this.detailCategory = '',
      this.fit = '기본',
      this.assetPath,
      this.imageBytes,
      this.tintColor,
      this.colorizeAsset = false,
      this.purchaseDate,
      this.registrationMethod = '기본 옷장',
      this.lastWornLabel = '미기록'});
  final String name;
  final String category;
  final String detailCategory;
  final String fit;
  final String color;
  final String location;
  final Color tone;
  final String? assetPath;
  final Uint8List? imageBytes;
  final Color? tintColor;
  final bool colorizeAsset;
  final DateTime? purchaseDate;
  final String registrationMethod;
  final String lastWornLabel;
}

const starterBasicGarments = <GarmentItem>[
  GarmentItem(
    name: '블랙 베이직 반팔티',
    category: '상의',
    detailCategory: '반팔티',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE7EEE9),
    assetPath: 'assets/garment_samples/unisex_tshirt_basic_shortsleeve.png.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '화이트 베이직 반팔티',
    category: '상의',
    detailCategory: '반팔티',
    color: '화이트',
    location: '기본 옷장',
    tone: Color(0xFFF1F2EE),
    assetPath: 'assets/garment_samples/unisex_tshirt_basic_shortsleeve.png.png',
    tintColor: Color(0xFFF6F5F1),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 베이직 긴팔티',
    category: '상의',
    detailCategory: '긴팔티',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE7EEE9),
    assetPath: 'assets/garment_samples/unisex_tshirt_basic_longsleeve.png.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '화이트 베이직 긴팔티',
    category: '상의',
    detailCategory: '긴팔티',
    color: '화이트',
    location: '기본 옷장',
    tone: Color(0xFFF1F2EE),
    assetPath: 'assets/garment_samples/unisex_tshirt_basic_longsleeve.png.png',
    tintColor: Color(0xFFF6F5F1),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '화이트 베이직 셔츠',
    category: '상의',
    detailCategory: '셔츠',
    color: '화이트',
    location: '기본 옷장',
    tone: Color(0xFFF0F3F1),
    assetPath: 'assets/garment_samples/unisex_shirt_basic_longsleeve.png',
    tintColor: Color(0xFFF6F5F1),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '라이트 블루 데님 셔츠',
    category: '상의',
    detailCategory: '데님 셔츠',
    color: '라이트 블루',
    location: '기본 옷장',
    tone: Color(0xFFDCECF7),
    assetPath: 'assets/garment_samples/unisex_shirt_denim_longsleeve.png',
    tintColor: Color(0xFF739BC2),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '그레이 베이직 후드',
    category: '상의',
    detailCategory: '후드',
    color: '그레이',
    location: '기본 옷장',
    tone: Color(0xFFE9ECEE),
    assetPath: 'assets/garment_samples/unisex_hoodie_basic.png.png',
    tintColor: Color(0xFF8C9298),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '베이지 베이직 가디건',
    category: '아우터',
    detailCategory: '가디건',
    color: '베이지',
    location: '기본 옷장',
    tone: Color(0xFFF3E6D2),
    assetPath: 'assets/garment_samples/unisex_cardigan_basic_longsleeve.png',
    tintColor: Color(0xFFD8BE98),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 베이직 후드 집업',
    category: '아우터',
    detailCategory: '후드 집업',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE6ECE9),
    assetPath: 'assets/garment_samples/unisex_hoodie_zipup.png.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 와이드 슬랙스',
    category: '하의',
    detailCategory: '와이드 슬랙스',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE3E9EC),
    assetPath: 'assets/garment_samples/unisex_slacks_wide.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '베이지 스트레이트 팬츠',
    category: '하의',
    detailCategory: '스트레이트 팬츠',
    color: '베이지',
    location: '기본 옷장',
    tone: Color(0xFFF4E7D4),
    assetPath: 'assets/garment_samples/unisex_pants_straight.png',
    tintColor: Color(0xFFD8BE98),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '라이트 블루 스트레이트 데님',
    category: '하의',
    detailCategory: '스트레이트 데님',
    color: '라이트 블루',
    location: '기본 옷장',
    tone: Color(0xFFDCECF7),
    assetPath:
        'assets/garment_samples/unisex_jeans_straight_lightblue_denim.png',
    tintColor: Color(0xFF739BC2),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '카키 카고 팬츠',
    category: '하의',
    detailCategory: '카고 팬츠',
    color: '카키',
    location: '기본 옷장',
    tone: Color(0xFFE9E8DA),
    assetPath: 'assets/garment_samples/unisex_pants_cargo.png',
    tintColor: Color(0xFF817B55),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '그레이 조거 팬츠',
    category: '하의',
    detailCategory: '조거 팬츠',
    color: '그레이',
    location: '기본 옷장',
    tone: Color(0xFFE7EBED),
    assetPath: 'assets/garment_samples/unisex_pants_jogger.png',
    tintColor: Color(0xFF8C9298),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '베이지 버뮤다 팬츠',
    category: '하의',
    detailCategory: '버뮤다 팬츠',
    color: '베이지',
    location: '기본 옷장',
    tone: Color(0xFFF3E7D6),
    assetPath: 'assets/garment_samples/unisex_shorts_bermuda.png',
    tintColor: Color(0xFFD8BE98),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 베이직 쇼츠',
    category: '하의',
    detailCategory: '반바지',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE7ECEA),
    assetPath: 'assets/garment_samples/unisex_shorts_basic.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 싱글 블레이저',
    category: '아우터',
    detailCategory: '블레이저',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE5EBE8),
    assetPath: 'assets/garment_samples/unisex_blazer_single_basi.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '베이지 롱 트렌치코트',
    category: '아우터',
    detailCategory: '롱 트렌치',
    color: '베이지',
    location: '기본 옷장',
    tone: Color(0xFFF5E5CB),
    assetPath: 'assets/garment_samples/unisex_outer_trench_long.png',
    tintColor: Color(0xFFD8BE98),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 베이직 봄버 재킷',
    category: '아우터',
    detailCategory: '봄버 재킷',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE4EAE7),
    assetPath: 'assets/garment_samples/unisex_outer_bomber.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '라이트 블루 크롭 데님 재킷',
    category: '아우터',
    detailCategory: '데님 재킷',
    color: '라이트 블루',
    location: '기본 옷장',
    tone: Color(0xFFDCECF7),
    assetPath: 'assets/garment_samples/unisex_outer_denimjacket_cropped.png',
    tintColor: Color(0xFF739BC2),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '크림 베이직 바람막이',
    category: '아우터',
    detailCategory: '바람막이',
    color: '크림',
    location: '기본 옷장',
    tone: Color(0xFFF1EBDD),
    assetPath: 'assets/garment_samples/unisex_outer_windbreaker.png',
    tintColor: Color(0xFFE6D8BF),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '베이지 숏 코트',
    category: '아우터',
    detailCategory: '숏 코트',
    color: '베이지',
    location: '기본 옷장',
    tone: Color(0xFFF2E5D2),
    assetPath: 'assets/garment_samples/unisex_outer_coat_short.png',
    tintColor: Color(0xFFD8BE98),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '카멜 롱 코트',
    category: '아우터',
    detailCategory: '롱 코트',
    color: '카멜',
    location: '기본 옷장',
    tone: Color(0xFFF2DFCF),
    assetPath: 'assets/garment_samples/unisex_outer_coat_long.png',
    tintColor: Color(0xFFB8895C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 숏 패딩',
    category: '아우터',
    detailCategory: '숏 패딩',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE4EBE8),
    assetPath: 'assets/garment_samples/unisex_outer_puffer_short.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '베이지 롱 패딩',
    category: '아우터',
    detailCategory: '롱 패딩',
    color: '베이지',
    location: '기본 옷장',
    tone: Color(0xFFF2E7D7),
    assetPath: 'assets/garment_samples/unisex_outer_puffer_long.png',
    tintColor: Color(0xFFD8BE98),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '크림 패딩 조끼',
    category: '아우터',
    detailCategory: '패딩 조끼',
    color: '크림',
    location: '기본 옷장',
    tone: Color(0xFFF3ECDF),
    assetPath: 'assets/garment_samples/unisex_outer_puffer_vest.png',
    tintColor: Color(0xFFE6D8BF),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '화이트 로우탑 스니커즈',
    category: '신발',
    detailCategory: '로우탑 스니커즈',
    color: '화이트',
    location: '기본 옷장',
    tone: Color(0xFFE8F1ED),
    assetPath: 'assets/garment_samples/unisex_shoes_sneakers_lowtop.png',
    tintColor: Color(0xFFF6F5F1),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 클래식 로퍼',
    category: '신발',
    detailCategory: '로퍼',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFF0E4D5),
    assetPath: 'assets/garment_samples/unisex_shoes_loafer_black.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '화이트 러닝화',
    category: '신발',
    detailCategory: '러닝화',
    color: '화이트',
    location: '기본 옷장',
    tone: Color(0xFFE8EEF1),
    assetPath: 'assets/garment_samples/unisex_shoes_running.png',
    tintColor: Color(0xFFF6F5F1),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '블랙 하이탑 스니커즈',
    category: '신발',
    detailCategory: '하이탑 스니커즈',
    color: '블랙',
    location: '기본 옷장',
    tone: Color(0xFFE7ECEA),
    assetPath: 'assets/garment_samples/unisex_shoes_sneakers_hightop.png',
    tintColor: Color(0xFF25292C),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
  GarmentItem(
    name: '화이트 베이직 나시티',
    category: '상의',
    detailCategory: '나시티',
    color: '화이트',
    location: '기본 옷장',
    tone: Color(0xFFF1F2EE),
    assetPath: 'assets/garment_samples/unisex_tanktop_basic_sleeveless.png.png',
    tintColor: Color(0xFFF6F5F1),
    colorizeAsset: true,
    registrationMethod: '베이직 아이템 자동 채우기',
  ),
];

GarmentItem _genderStarterItem({
  required String name,
  required String category,
  required String detailCategory,
  required String color,
  required String assetPath,
  required Color tintColor,
  required Color tone,
}) =>
    GarmentItem(
      name: name,
      category: category,
      detailCategory: detailCategory,
      color: color,
      location: '기본 옷장',
      tone: tone,
      assetPath: assetPath,
      tintColor: tintColor,
      colorizeAsset: true,
      registrationMethod: '성별 베이직 아이템 자동 채우기',
    );

final maleStarterGarments = <GarmentItem>[
  _genderStarterItem(
      name: '네이비 싱글 블레이저',
      category: '아우터',
      detailCategory: '블레이저',
      color: '네이비',
      assetPath: 'assets/garment_samples/unisex_blazer_single_basi.png',
      tintColor: const Color(0xFF33445F),
      tone: const Color(0xFFE4E9F0)),
  _genderStarterItem(
      name: '차콜 와이드 슬랙스',
      category: '하의',
      detailCategory: '와이드 슬랙스',
      color: '차콜',
      assetPath: 'assets/garment_samples/unisex_slacks_wide.png',
      tintColor: const Color(0xFF4D5258),
      tone: const Color(0xFFE7E9EA)),
  _genderStarterItem(
      name: '올리브 봄버 재킷',
      category: '아우터',
      detailCategory: '봄버 재킷',
      color: '카키',
      assetPath: 'assets/garment_samples/unisex_outer_bomber.png',
      tintColor: const Color(0xFF66704A),
      tone: const Color(0xFFE8EBDD)),
  _genderStarterItem(
      name: '네이비 베이직 셔츠',
      category: '상의',
      detailCategory: '셔츠',
      color: '네이비',
      assetPath: 'assets/garment_samples/unisex_shirt_basic_longsleeve.png',
      tintColor: const Color(0xFF33445F),
      tone: const Color(0xFFE4E9F0)),
  _genderStarterItem(
      name: '브라운 클래식 로퍼',
      category: '신발',
      detailCategory: '로퍼',
      color: '브라운',
      assetPath: 'assets/garment_samples/unisex_shoes_loafer_black.png',
      tintColor: const Color(0xFF6F4D3B),
      tone: const Color(0xFFF1E5DC)),
  _genderStarterItem(
      name: '그레이 숏 코트',
      category: '아우터',
      detailCategory: '숏 코트',
      color: '그레이',
      assetPath: 'assets/garment_samples/unisex_outer_coat_short.png',
      tintColor: const Color(0xFF8C9298),
      tone: const Color(0xFFE9ECEE)),
  _genderStarterItem(
      name: '네이비 카고 팬츠',
      category: '하의',
      detailCategory: '카고 팬츠',
      color: '네이비',
      assetPath: 'assets/garment_samples/unisex_pants_cargo.png',
      tintColor: const Color(0xFF33445F),
      tone: const Color(0xFFE4E9F0)),
  _genderStarterItem(
      name: '블랙 베이직 바람막이',
      category: '아우터',
      detailCategory: '바람막이',
      color: '블랙',
      assetPath: 'assets/garment_samples/unisex_outer_windbreaker.png',
      tintColor: const Color(0xFF25292C),
      tone: const Color(0xFFE4EBE8)),
  _genderStarterItem(
      name: '크림 니트 가디건',
      category: '아우터',
      detailCategory: '가디건',
      color: '크림',
      assetPath: 'assets/garment_samples/unisex_cardigan_basic_longsleeve.png',
      tintColor: const Color(0xFFE6D8BF),
      tone: const Color(0xFFF3ECDF)),
  _genderStarterItem(
      name: '다크 데님 셔츠',
      category: '상의',
      detailCategory: '데님 셔츠',
      color: '다크 블루',
      assetPath: 'assets/garment_samples/unisex_shirt_denim_longsleeve.png',
      tintColor: const Color(0xFF456887),
      tone: const Color(0xFFDDE8F0)),
];

final femaleStarterGarments = <GarmentItem>[
  _genderStarterItem(
      name: '코랄 A라인 미디 원피스',
      category: '원피스',
      detailCategory: 'A라인 긴팔 미디 원피스',
      color: '코랄',
      assetPath:
          'assets/garment_samples/female_dress_aline_longsleeve_midi.png',
      tintColor: const Color(0xFFE8A4A0),
      tone: const Color(0xFFF7E4E3)),
  _genderStarterItem(
      name: '아이보리 A라인 미디 원피스',
      category: '원피스',
      detailCategory: 'A라인 긴팔 미디 원피스',
      color: '아이보리',
      assetPath:
          'assets/garment_samples/female_dress_aline_longsleeve_midi.png',
      tintColor: const Color(0xFFE9DFC9),
      tone: const Color(0xFFF5EFE3)),
  _genderStarterItem(
      name: '핑크 베이직 가디건',
      category: '아우터',
      detailCategory: '가디건',
      color: '핑크',
      assetPath: 'assets/garment_samples/unisex_cardigan_basic_longsleeve.png',
      tintColor: const Color(0xFFDDA6B4),
      tone: const Color(0xFFF7E4E9)),
  _genderStarterItem(
      name: '스카이 크롭 데님 재킷',
      category: '아우터',
      detailCategory: '데님 재킷',
      color: '라이트 블루',
      assetPath: 'assets/garment_samples/unisex_outer_denimjacket_cropped.png',
      tintColor: const Color(0xFF86ACCF),
      tone: const Color(0xFFDCECF7)),
  _genderStarterItem(
      name: '크림 숏 코트',
      category: '아우터',
      detailCategory: '숏 코트',
      color: '크림',
      assetPath: 'assets/garment_samples/unisex_outer_coat_short.png',
      tintColor: const Color(0xFFE6D8BF),
      tone: const Color(0xFFF3ECDF)),
  _genderStarterItem(
      name: '베이지 와이드 슬랙스',
      category: '하의',
      detailCategory: '와이드 슬랙스',
      color: '베이지',
      assetPath: 'assets/garment_samples/unisex_slacks_wide.png',
      tintColor: const Color(0xFFD8BE98),
      tone: const Color(0xFFF4E7D4)),
  _genderStarterItem(
      name: '핑크 베이직 셔츠',
      category: '상의',
      detailCategory: '셔츠',
      color: '핑크',
      assetPath: 'assets/garment_samples/unisex_shirt_basic_longsleeve.png',
      tintColor: const Color(0xFFDDA6B4),
      tone: const Color(0xFFF7E4E9)),
  _genderStarterItem(
      name: '라벤더 후드 집업',
      category: '아우터',
      detailCategory: '후드 집업',
      color: '라벤더',
      assetPath: 'assets/garment_samples/unisex_hoodie_zipup.png.png',
      tintColor: const Color(0xFFAC9AC8),
      tone: const Color(0xFFEBE4F5)),
  _genderStarterItem(
      name: '핑크 로우탑 스니커즈',
      category: '신발',
      detailCategory: '로우탑 스니커즈',
      color: '핑크',
      assetPath: 'assets/garment_samples/unisex_shoes_sneakers_lowtop.png',
      tintColor: const Color(0xFFDDA6B4),
      tone: const Color(0xFFF7E4E9)),
  _genderStarterItem(
      name: '아이보리 롱 트렌치코트',
      category: '아우터',
      detailCategory: '롱 트렌치',
      color: '아이보리',
      assetPath: 'assets/garment_samples/unisex_outer_trench_long.png',
      tintColor: const Color(0xFFE9DFC9),
      tone: const Color(0xFFF5EFE3)),
];

List<GarmentItem> starterGarmentsForGender(String gender) =>
    List<GarmentItem>.unmodifiable([
      ...starterBasicGarments,
      ...(gender == '남' ? maleStarterGarments : femaleStarterGarments),
    ]);

const sampleGarments = [
  GarmentItem(
      name: '아이보리 린넨 셔츠',
      category: '상의',
      color: '아이보리',
      location: '안방 옷장',
      tone: Color(0xFFF7E8C9),
      assetPath: 'assets/garments/shirt-ivory-linen.png'),
  GarmentItem(
      name: '블랙 와이드 슬랙스',
      category: '하의',
      color: '블랙',
      location: '안방 옷장',
      tone: Color(0xFFDFEDF6),
      assetPath: 'assets/garments/pants-black-wide.png'),
  GarmentItem(
      name: '베이지 로퍼',
      category: '신발',
      color: '베이지',
      location: '신발장',
      tone: Color(0xFFF7E4E9),
      assetPath: 'assets/garments/shoes-beige-loafers.png'),
  GarmentItem(
      name: '민트 가디건',
      category: '아우터',
      color: '민트',
      location: '서랍 2칸',
      tone: Color(0xFFE4F3ED),
      assetPath: 'assets/garments/cardigan-mint.png'),
  GarmentItem(
      name: '네이비 데님',
      category: '하의',
      color: '네이비',
      location: '안방 옷장',
      tone: Color(0xFFEBE4F5),
      assetPath: 'assets/garments/jeans-navy-straight.png'),
  GarmentItem(
      name: '화이트 스니커즈',
      category: '신발',
      color: '화이트',
      location: '신발장',
      tone: Color(0xFFE9F0DC),
      assetPath: 'assets/garments/shoes-white-sneakers.png'),
];

class GarmentVisual extends StatelessWidget {
  const GarmentVisual(
      {super.key,
      required this.item,
      required this.size,
      this.fillUploadedPhoto = false,
      this.radius = 16});
  final GarmentItem item;
  final double size;
  final bool fillUploadedPhoto;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.lerp(Colors.white, item.tone, .76)!, item.tone],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radius)),
          child: item.imageBytes != null
              ? Padding(
                  padding: EdgeInsets.all(fillUploadedPhoto ? 0 : 8),
                  child: Image.memory(item.imageBytes!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: fillUploadedPhoto ? BoxFit.cover : BoxFit.contain,
                      semanticLabel: item.name))
              : item.assetPath == null
                  ? Icon(
                      switch (item.category) {
                        '상의' => Icons.checkroom_rounded,
                        '하의' => Icons.dry_cleaning_rounded,
                        '신발' => Icons.ice_skating_rounded,
                        _ => Icons.style_rounded
                      },
                      size: size == double.infinity ? 46 : size * .45,
                      color: item.tone == AppColors.ink
                          ? Colors.white
                          : AppColors.ink)
                  : Padding(
                      padding: EdgeInsets.all(fillUploadedPhoto ? 0 : 8),
                      child: item.colorizeAsset && item.tintColor != null
                          ? ColorizedGarmentAsset(
                              assetPath: item.assetPath!,
                              color: item.tintColor!,
                              fit: fillUploadedPhoto
                                  ? BoxFit.cover
                                  : BoxFit.contain,
                              semanticLabel: item.name)
                          : Image.asset(item.assetPath!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: fillUploadedPhoto
                                  ? BoxFit.cover
                                  : BoxFit.contain,
                              semanticLabel: item.name)),
        ),
      );
}
