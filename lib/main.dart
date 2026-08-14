import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_options.dart';
import 'services/app_auth.dart';
import 'services/backend_service.dart';
import 'services/location_weather_service.dart';
import 'services/user_profile_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Paperlogy',
        visualDensity: VisualDensity.standard,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: TextStyle(fontSize: 15, height: 1.5),
          bodySmall: TextStyle(fontSize: 13, height: 1.45),
          labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(size: AppA11y.iconSize),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size.square(AppA11y.touchTarget),
            iconSize: AppA11y.iconSize,
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, AppA11y.controlHeight),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, AppA11y.controlHeight),
            textStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, AppA11y.touchTarget),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          helperStyle: TextStyle(fontSize: 13, color: AppColors.muted),
          hintStyle: TextStyle(fontSize: 15, color: AppColors.muted),
          labelStyle: TextStyle(fontSize: 15, color: AppColors.muted),
          errorStyle: TextStyle(fontSize: 13),
        ),
        chipTheme: const ChipThemeData(
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 72,
          labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        tooltipTheme: const TooltipThemeData(
          textStyle: TextStyle(fontSize: 13, color: Colors.white),
          waitDuration: Duration(milliseconds: 400),
        ),
      ),
      home: AppFlow(auth: auth),
    );
  }
}

class AppColors {
  static const ink = Color(0xFF212B38);
  static const paper = Color(0xFFFFFCF7);
  static const mist = Color(0xFFF2F5F4);
  static const mint = Color(0xFF267968);
  static const mintDark = Color(0xFF267968);
  static const coral = Color(0xFFFF9775);
  static const sky = Color(0xFF9BC7ED);
  static const lavender = Color(0xFFCBBDEE);
  static const sand = Color(0xFFF3D393);
  static const line = Color(0xFFE5E9E7);
  static const muted = Color(0xFF596561);
  static const onDarkMuted = Color(0xE6FFFFFF);
}

class AppA11y {
  static const touchTarget = 48.0;
  static const controlHeight = 52.0;
  static const iconSize = 24.0;
  static const compactIconSize = 20.0;
  static const captionSize = 12.0;
  static const metadataSize = 13.0;
}

class AppRadius {
  static const card = 20.0;
  static const control = 14.0;
  static const media = 16.0;
}

String formatKoreanDate(DateTime date) {
  const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}';
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
  GarmentItem? _onboardingGarment;
  bool _isRestoringSession = true;
  late final AppAuth _auth;
  UserProfileStore? _profileStore;
  BackendService? _backend;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ??
        (Firebase.apps.isEmpty ? PreviewAppAuth() : FirebaseAppAuth());
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
    if (!mounted) return;
    setState(() {
      _stage = completed ? AppStage.home : AppStage.onboarding;
      _isRestoringSession = false;
    });
  }

  void _goTo(AppStage stage) => setState(() => _stage = stage);

  Future<void> _signedIn(AppSignInResult result) async {
    final completed =
        await (_profileStore?.hasCompletedOnboarding(result.userId) ??
            Future<bool>.value(false));
    if (!mounted) return;
    setState(() => _stage = completed ? AppStage.home : AppStage.onboarding);
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) _goTo(AppStage.landing);
  }

  Future<void> _deleteAccount() async {
    final userId = _auth.currentUserId;
    try {
      await _backend?.deleteMyData();
    } catch (_) {
      // Functions 미배포 개발 환경에서는 로컬 및 인증 계정 삭제를 계속 진행합니다.
    }
    if (userId != null) await _profileStore?.deleteProfile(userId);
    await _auth.deleteCurrentUser();
    if (!mounted) return;
    setState(() {
      _onboardingGarment = null;
      _stage = AppStage.landing;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringSession) {
      return const Scaffold(
        backgroundColor: AppColors.paper,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return switch (_stage) {
      AppStage.landing => LandingScreen(
          auth: _auth,
          onSignedIn: _signedIn,
        ),
      AppStage.onboarding => OnboardingScreen(onDone: (garment) {
          final userId = _auth.currentUserId;
          if (userId != null) {
            unawaited(_profileStore?.markOnboardingCompleted(userId));
          }
          setState(() {
            _onboardingGarment = garment;
            _stage = AppStage.home;
          });
        }),
      AppStage.home => MainShell(
          initialGarment: _onboardingGarment,
          onLogout: _logout,
          onDeleteAccount: _deleteAccount),
    };
  }
}

enum AppStage { landing, onboarding, home }

class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    required this.auth,
    required this.onSignedIn,
  });
  final AppAuth auth;
  final Future<void> Function(AppSignInResult result) onSignedIn;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  bool _isSigningIn = false;
  late final String _characterAsset;

  @override
  void initState() {
    super.initState();
    _characterAsset =
        landingCharacterAssets[Random().nextInt(landingCharacterAssets.length)];
  }

  Future<void> _signIn() async {
    setState(() => _isSigningIn = true);
    try {
      final result = await widget.auth.signInWithGoogle();
      if (!mounted) return;
      if (result.isNewUser) {
        final accepted = await _requestSignupConsent();
        if (!accepted || !mounted) {
          await widget.auth.deleteCurrentUser();
          return;
        }
      }
      if (mounted) await widget.onSignedIn(result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Google 로그인에 실패했어요. 잠시 후 다시 시도해주세요.\n$error'),
      ));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<bool> _requestSignupConsent() async {
    var terms = false;
    var privacy = false;
    return await showModalBottomSheet<bool>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          showDragHandle: true,
          backgroundColor: AppColors.paper,
          builder: (sheetContext) => StatefulBuilder(
              builder: (sheetContext, setSheetState) => SafeArea(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('착착 가입 약관 동의',
                              style: TextStyle(
                                  fontSize: 21, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          const Text('처음 가입할 때 한 번만 동의하면 됩니다.',
                              style: TextStyle(color: AppColors.muted)),
                          const SizedBox(height: 14),
                          _ConsentRow(
                              value: terms,
                              label: '서비스 이용약관',
                              onChanged: (value) =>
                                  setSheetState(() => terms = value),
                              onOpen: () => _showPolicy(
                                  title: '서비스 이용약관',
                                  content:
                                      '착착은 사용자가 등록한 옷, 날씨와 일정 정보를 활용해 코디를 추천합니다. Google 계정으로 가입하며 등록 정보는 코디 추천 제공을 위해 처리됩니다.')),
                          _ConsentRow(
                              value: privacy,
                              label: '개인정보 처리방침',
                              onChanged: (value) =>
                                  setSheetState(() => privacy = value),
                              onOpen: () => _showPolicy(
                                  title: '개인정보 처리방침',
                                  content:
                                      'Google 계정의 이름·이메일·프로필 사진과 사용자가 입력한 옷장·일정·선호 정보를 로그인과 개인화 추천 목적으로 처리합니다. 회원 탈퇴 시 착착 데이터를 삭제합니다.')),
                          const SizedBox(height: 14),
                          FilledButton(
                              onPressed: terms && privacy
                                  ? () => Navigator.of(sheetContext).pop(true)
                                  : null,
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.ink,
                                  minimumSize: const Size.fromHeight(52)),
                              child: const Text('동의하고 가입하기')),
                          const SizedBox(height: 8),
                          OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(false),
                              style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50)),
                              child: const Text('가입 취소')),
                        ]),
                  ))),
        ) ??
        false;
  }

  Future<void> _showPolicy({required String title, required String content}) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        backgroundColor: AppColors.paper,
        builder: (context) => SafeArea(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Text(content,
                    style: const TextStyle(
                        fontSize: 12, height: 1.6, color: Color(0xFF63706C))),
                const SizedBox(height: 18),
                OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50)),
                    child: const Text('확인')),
              ]),
        )),
      );

  @override
  Widget build(BuildContext context) {
    final landing = _LandingCanvas(
      characterAsset: _characterAsset,
      isSigningIn: _isSigningIn,
      onSignIn: _signIn,
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 980) return landing;
      final phoneScale = min(1.0, max(.7, (constraints.maxHeight - 64) / 830));
      return Scaffold(
        backgroundColor: const Color(0xFFF0F3F1),
        body: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 32),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 410 * phoneScale,
                  height: 830 * phoneScale,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: _PortfolioPhoneFrame(child: landing),
                  ),
                ),
                const SizedBox(width: 72),
                const _PortfolioIntro(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _LandingCanvas extends StatelessWidget {
  const _LandingCanvas(
      {required this.characterAsset,
      required this.isSigningIn,
      required this.onSignIn});

  final String characterAsset;
  final bool isSigningIn;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.paper,
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF4FFFB), Color(0xFFFFF3DC)],
                  ),
                ),
              ),
            ),
            Positioned(
                right: -72,
                top: 92,
                child: _LandingGlow(
                    color: const Color(0xFFBDECDD).withValues(alpha: .66),
                    size: 220)),
            Positioned(
                left: -92,
                bottom: 80,
                child: _LandingGlow(
                    color: const Color(0xFFFFD785).withValues(alpha: .52),
                    size: 230)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LandingHeader(),
                    const SizedBox(height: 6),
                    Expanded(
                      child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight),
                                  child: IntrinsicHeight(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Spacer(),
                                        Center(
                                          child: Image.asset(
                                            characterAsset,
                                            width: 215,
                                            height: 215,
                                            fit: BoxFit.contain,
                                            semanticLabel:
                                                '첫 화면에 무작위로 등장하는 착착 메이트',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'MY PERSONAL OUTFIT ASSISTANT',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: AppA11y.captionSize,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.8,
                                              color: AppColors.mintDark),
                                        ),
                                        const SizedBox(height: 12),
                                        Text.rich(
                                          const TextSpan(children: [
                                            TextSpan(text: '내 옷으로,\n'),
                                            TextSpan(
                                                text: '오늘의 코디가 착착.',
                                                style: TextStyle(
                                                    color: AppColors.mintDark)),
                                          ]),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 32,
                                              height: 1.18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.ink,
                                              letterSpacing: -1.1),
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          '날씨와 오늘의 일정을 보고\n코디 메이트가 함께 골라줘요.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              height: 1.5,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.muted),
                                        ),
                                        const Spacer(),
                                        const LandingPreview(),
                                        const SizedBox(height: 18),
                                        FilledButton.icon(
                                          onPressed:
                                              isSigningIn ? null : onSignIn,
                                          icon: isSigningIn
                                              ? const SizedBox.square(
                                                  dimension: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: AppColors.ink))
                                              : const GoogleMark(),
                                          label: Text(isSigningIn
                                              ? 'Google 계정 연결 중...'
                                              : 'Google로 시작하기'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            disabledBackgroundColor: Colors
                                                .white
                                                .withValues(alpha: .75),
                                            foregroundColor: AppColors.ink,
                                            elevation: 0,
                                            side: const BorderSide(
                                                color: AppColors.line),
                                            minimumSize:
                                                const Size.fromHeight(58),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.control)),
                                            textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )),
                    ),
                  ],
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
        const Row(children: [
          Text('9:41',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          Spacer(),
          Icon(Icons.circle, size: 9),
          SizedBox(width: 4),
          Icon(Icons.circle, size: 9),
          SizedBox(width: 4),
          Icon(Icons.circle, size: 9),
          SizedBox(width: 5),
          Icon(Icons.signal_cellular_alt_rounded, size: 13),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          const Text('착착',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2)),
          const SizedBox(width: 6),
          Text('CHAKCHAK',
              style: TextStyle(
                  fontSize: AppA11y.captionSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.ink.withValues(alpha: .82))),
        ]),
      ]);
}

class _LandingGlow extends StatelessWidget {
  const _LandingGlow({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _PortfolioPhoneFrame extends StatelessWidget {
  const _PortfolioPhoneFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        width: 410,
        height: 830,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(48),
          boxShadow: const [
            BoxShadow(
                color: Color(0x2B1B2A26), blurRadius: 32, offset: Offset(0, 18))
          ],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(39), child: child),
      );
}

class _PortfolioIntro extends StatelessWidget {
  const _PortfolioIntro();
  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 470,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHAKCHAK PORTFOLIO PROTOTYPE',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: AppColors.mintDark)),
            SizedBox(height: 18),
            Text('내 옷장 × 오늘 날씨 ×\n오늘 일정',
                style: TextStyle(
                    fontSize: 40,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -1.4)),
            SizedBox(height: 22),
            Text('정적인 시안이 아니라 클릭하고 대화할 수 있는 Flutter 프로토타입입니다.',
                style: TextStyle(
                    fontSize: 15, height: 1.6, color: AppColors.muted)),
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
    (
      icon: Icons.wb_sunny_rounded,
      title: '28° · 오후 외부 미팅',
      outfit: '린넨 셔츠 + 블랙 슬랙스 어때요?'
    ),
    (
      icon: Icons.umbrella_rounded,
      title: '19° · 저녁 전시 관람',
      outfit: '방수 재킷 + 스트레이트 데님이 좋아요.'
    ),
    (
      icon: Icons.cloud_rounded,
      title: '12° · 아침 출근',
      outfit: '가벼운 니트 + 트렌치코트를 챙겨요.'
    ),
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
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic);
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final previewHeight = 82.0 + max(0.0, textScale - 1.0) * 44;
    return Column(children: [
      SizedBox(
        height: previewHeight,
        child: PageView.builder(
          controller: _controller,
          onPageChanged: (value) => setState(() {
            _physicalPage = value;
            _page = value % _examples.length;
          }),
          itemBuilder: (context, index) {
            final example = _examples[index % _examples.length];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0x99FFFFFF),
                  borderRadius: BorderRadius.circular(26)),
              child: Row(children: [
                Icon(example.icon, color: AppColors.ink, size: 32),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(example.title,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(example.outfit,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF326257))),
                    ])),
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 7),
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              _examples.length,
              (index) => Semantics(
                    button: true,
                    selected: index == _page,
                    label: '${index + 1}번째 코디 예시 보기',
                    child: InkWell(
                      onTap: () {
                        var target = _physicalPage -
                            (_physicalPage % _examples.length) +
                            index;
                        if (target < _physicalPage) target += _examples.length;
                        _controller.animateToPage(target,
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic);
                        _startTimer();
                      },
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox.square(
                        dimension: AppA11y.touchTarget,
                        child: Center(
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: index == _page ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: index == _page
                                      ? AppColors.ink
                                      : const Color(0x66253A34),
                                  borderRadius: BorderRadius.circular(99))),
                        ),
                      ),
                    ),
                  ))),
    ]);
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final ValueChanged<GarmentItem?> onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  String selectedCity = '서울';
  final Set<String> styles = {'미니멀'};
  GarmentItem? firstGarment;
  Color firstGarmentTone = const [
    Color(0xFFDFF4EC),
    Color(0xFFF8DFB5),
    Color(0xFFE6DDF5),
    Color(0xFFDCECF7),
    Color(0xFFF8DFE5),
    Color(0xFFE5EFD9)
  ][Random().nextInt(6)];

  void _next() {
    if (step == 2) {
      widget.onDone(firstGarment);
    } else {
      setState(() => step += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardingCity(
        city: selectedCity,
        onCityChanged: (value) => setState(() => selectedCity = value),
      ),
      _OnboardingStyle(
        selected: styles,
        onToggle: (value) => setState(() =>
            styles.contains(value) ? styles.remove(value) : styles.add(value)),
      ),
      _OnboardingCloset(
        garment: firstGarment,
        tone: firstGarmentTone,
        onAdd: () async {
          final garment = await Navigator.of(context).push<GarmentItem>(
            MaterialPageRoute(
                builder: (_) => const AddGarmentScreen(title: '첫 옷 등록')),
          );
          if (garment != null && mounted)
            setState(() {
              firstGarment = garment;
              const tones = [
                Color(0xFFDFF4EC),
                Color(0xFFF8DFB5),
                Color(0xFFE6DDF5),
                Color(0xFFDCECF7),
                Color(0xFFF8DFE5),
                Color(0xFFE5EFD9)
              ];
              firstGarmentTone = tones[Random().nextInt(tones.length)];
            });
        },
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                for (var index = 0; index < 3; index++) ...[
                  Expanded(
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          height: 8,
                          decoration: BoxDecoration(
                              color: index <= step
                                  ? AppColors.mintDark
                                  : AppColors.line,
                              borderRadius: BorderRadius.circular(10)))),
                  if (index < 2) const SizedBox(width: 6),
                ],
              ]),
              Expanded(
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: pages[step])),
              FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                ),
                child: Text(step == 2 ? '착착 시작하기' : '다음'),
              ),
              if (step == 2)
                TextButton(
                    onPressed: () => widget.onDone(firstGarment),
                    child: const Text('나중에 등록할게요')),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCity extends StatelessWidget {
  const _OnboardingCity({required this.city, required this.onCityChanged});
  final String city;
  final ValueChanged<String> onCityChanged;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('city'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const MateAvatar(size: 112, mood: MateMood.sunny),
          const SizedBox(height: 26),
          Text('오늘의 날씨는\n어디를 기준으로 볼까요?',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1.18)),
          const SizedBox(height: 10),
          const Text('내 위치를 찾거나 지역을 직접 고를 수 있어요.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => onCityChanged('내 위치'),
            icon:
                SvgPicture.asset('assets/icons/map.svg', width: 24, height: 24),
            label: const Align(
                alignment: Alignment.centerLeft, child: Text('내 위치로 찾기')),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.mint)),
          ),
          const SizedBox(height: 12),
          Expanded(
              child: SingleChildScrollView(
                  child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: koreaRegions
                .map((name) => ChoiceChip(
                    label: Text(name),
                    labelStyle: TextStyle(
                        color: city == name ? Colors.white : AppColors.ink),
                    checkmarkColor: Colors.white,
                    selected: city == name,
                    onSelected: (_) => onCityChanged(name),
                    selectedColor: AppColors.mint,
                    side: const BorderSide(color: AppColors.line)))
                .toList(),
          ))),
          const SizedBox(height: 8),
        ],
      );
}

class _OnboardingStyle extends StatelessWidget {
  const _OnboardingStyle({required this.selected, required this.onToggle});
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('style'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const MateAvatar(size: 112, mood: MateMood.thinking),
          const SizedBox(height: 26),
          Text('평소 좋아하는 스타일을\n알려주세요.',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1.18)),
          const SizedBox(height: 10),
          const Text('여러 개를 골라도 괜찮아요. 나중에 바꿀 수 있어요.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 26),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: ['미니멀', '캐주얼', '페미닌', '모던', '스트릿', '클래식']
                .map((name) => FilterChip(
                      label: Text(name),
                      selected: selected.contains(name),
                      onSelected: (_) => onToggle(name),
                      selectedColor: AppColors.lavender,
                      side: const BorderSide(color: AppColors.line),
                    ))
                .toList(),
          ),
          const Spacer(flex: 2),
        ],
      );
}

class _OnboardingCloset extends StatelessWidget {
  const _OnboardingCloset(
      {required this.garment, required this.tone, required this.onAdd});
  final GarmentItem? garment;
  final Color tone;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
        key: const ValueKey('closet'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const MateAvatar(size: 112, mood: MateMood.excited),
          const SizedBox(height: 26),
          Text('옷 한 벌만 먼저\n보여줄래요?',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1.18)),
          const SizedBox(height: 10),
          const Text('사진을 찍으면 착착 메이트가 종류와 색을 먼저 찾아볼게요.',
              style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 24),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: 160,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: garment == null ? AppColors.mist : tone,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line)),
              child: garment == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 38, color: AppColors.mintDark),
                          SizedBox(height: 9),
                          Text('사진으로 첫 옷 등록하기',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(height: 5),
                          Text('사진을 고른 뒤 옷 정보를 입력해요.',
                              style: TextStyle(
                                  fontSize: AppA11y.captionSize,
                                  color: AppColors.muted))
                        ])
                  : Stack(fit: StackFit.expand, children: [
                      Padding(
                          padding: const EdgeInsets.all(10),
                          child: GarmentVisual(
                              item: garment!,
                              size: double.infinity,
                              fillUploadedPhoto: true)),
                      const Positioned(
                          right: 10,
                          bottom: 10,
                          child: Chip(
                              label: Text('다시 등록하기'),
                              avatar: Icon(Icons.edit_outlined, size: 17)))
                    ]),
            ),
          ),
          const Spacer(flex: 2),
        ],
      );
}

class MainShell extends StatefulWidget {
  const MainShell(
      {super.key,
      required this.onLogout,
      required this.onDeleteAccount,
      this.initialGarment});
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final GarmentItem? initialGarment;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  bool outfitSaved = false;
  late final List<GarmentItem> garments;

  @override
  void initState() {
    super.initState();
    garments = List.of(sampleGarments);
    if (widget.initialGarment != null)
      garments.insert(0, widget.initialGarment!);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
          onAskMate: () => setState(() => index = 2),
          saved: outfitSaved,
          onSave: () => setState(() => outfitSaved = true),
          garments: garments),
      WardrobeScreen(
        garments: garments,
        outfitSaved: outfitSaved,
        onAdd: () async {
          final garment = await Navigator.of(context).push<GarmentItem>(
              MaterialPageRoute(builder: (_) => const AddGarmentScreen()));
          if (garment != null) setState(() => garments.insert(0, garment));
        },
      ),
      MateChatScreen(
          garments: garments, onExit: () => setState(() => index = 0)),
      ProfileScreen(
          onLogout: widget.onLogout, onDeleteAccount: widget.onDeleteAccount),
    ];
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 39),
            child: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              height: 66,
              backgroundColor: Colors.white,
              indicatorColor: AppColors.mint,
              labelTextStyle: MaterialStateProperty.resolveWith((states) =>
                  TextStyle(
                      color: states.contains(MaterialState.selected)
                          ? Colors.white
                          : const Color(0xFF8A9591),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              destinations: const [
                NavigationDestination(
                    icon: _NavSvgIcon('assets/icons/nav-home.svg'),
                    selectedIcon: _NavSvgIcon('assets/icons/nav-home.svg',
                        selected: true),
                    label: '오늘'),
                NavigationDestination(
                    icon: _NavSvgIcon('assets/icons/nav-wardrobe.svg'),
                    selectedIcon: _NavSvgIcon('assets/icons/nav-wardrobe.svg',
                        selected: true),
                    label: '내 옷장'),
                NavigationDestination(
                    icon: _NavSvgIcon('assets/icons/nav-mate.svg'),
                    selectedIcon: _NavSvgIcon('assets/icons/nav-mate.svg',
                        selected: true),
                    label: '메이트'),
                NavigationDestination(
                    icon: _NavSvgIcon('assets/icons/nav-my.svg'),
                    selectedIcon:
                        _NavSvgIcon('assets/icons/nav-my.svg', selected: true),
                    label: '마이'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSvgIcon extends StatelessWidget {
  const _NavSvgIcon(this.asset, {this.selected = false});
  final String asset;
  final bool selected;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        asset,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
            selected ? Colors.white : const Color(0xFF8A9591), BlendMode.srcIn),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key,
      required this.onAskMate,
      required this.saved,
      required this.onSave,
      required this.garments});
  final VoidCallback onAskMate;
  final bool saved;
  final VoidCallback onSave;
  final List<GarmentItem> garments;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationWeatherService _weatherService = LocationWeatherService();
  WeatherSnapshot? _weather;
  String _locationLabel = '서울 성동구';
  bool _weatherLoading = false;
  final List<TodaySchedule> schedules = [
    const TodaySchedule(id: 1, time: '09:00', title: '출근'),
    const TodaySchedule(id: 2, time: '14:00', title: '외부 미팅'),
  ];
  Future<void> _editSchedules() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (context) => ScheduleSheet(
        initialSchedules: schedules,
        onChanged: (updated) {
          if (!mounted) return;
          setState(() {
            schedules
              ..clear()
              ..addAll(updated);
          });
        },
      ),
    );
  }

  void _deleteSchedule(int id) =>
      setState(() => schedules.removeWhere((item) => item.id == id));

  Future<void> _refreshWeather() async {
    if (_weatherLoading) return;
    setState(() => _weatherLoading = true);
    try {
      final result = await _weatherService.loadCurrentWeather();
      if (!mounted) return;
      setState(() {
        _weather = result.weather;
        _locationLabel = result.locationLabel;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${result.weather.sourceLabel}를 새로 불러왔어요.'),
        duration: const Duration(seconds: 1),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('위치 권한과 기상청 API 연결을 확인해주세요.'),
      ));
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              sliver: SliverList(
                  delegate: SliverChildListDelegate([
                WeatherHero(
                  schedules: schedules,
                  weather: _weather,
                  locationLabel: _locationLabel,
                  loading: _weatherLoading,
                  onRefresh: _refreshWeather,
                ),
                const SizedBox(height: 15),
                _ScheduleCard(
                    schedules: schedules,
                    onAdd: _editSchedules,
                    onDelete: _deleteSchedule),
                const SizedBox(height: 20),
                OutfitCard(
                    saved: widget.saved,
                    onSave: widget.onSave,
                    onAskMate: widget.onAskMate,
                    scheduleContext: schedules
                        .map((item) => '${item.time} ${item.title}')
                        .join(', ')),
                const SizedBox(height: 28),
                SectionTitle(
                    title: '착착의 발견',
                    trailing: '더보기',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => DiscoveryScreen(
                            garments: widget.garments,
                            onWearOutfit: () => Navigator.of(context).pop())))),
                const SizedBox(height: 12),
                ReDiscoveryRow(garments: widget.garments),
              ])),
            ),
          ],
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
  });
  final List<TodaySchedule> schedules;
  final WeatherSnapshot? weather;
  final String locationLabel;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final heroHeight = 370.0 + max(0.0, textScale - 1.0) * 96;
    final titles = schedules.map((item) => item.title).join(' ');
    var asset = 'assets/characters/chakchak-picnic.png';
    var colors = const [
      Color(0xFF218F79),
      Color(0xFF32B595),
      Color(0xFF79D2A9)
    ];
    var foreground = Colors.white;
    var bubble = '가볍게 움직이기 좋은 옷과 햇빛을 가려줄 아이템을 챙겨볼까요?';
    if (RegExp(r'여행|공항|비행|출장|휴가|캠핑|숙박').hasMatch(titles)) {
      asset = 'assets/characters/chakchak-travel.png';
      colors = const [Color(0xFF168B8A), Color(0xFF2EAAA5), Color(0xFF70C9BB)];
      bubble = '여행 일정이 있어요. 오래 이동해도 편하고 사진에도 잘 나오는 코디로 골라볼까요?';
    } else if (RegExp(r'운동|헬스|러닝|요가|필라테스|수영|등산|축구|테니스').hasMatch(titles)) {
      asset = 'assets/characters/chakchak-exercise.png';
      colors = const [Color(0xFFF08A46), Color(0xFFF6AA54), Color(0xFFF3C66E)];
      bubble = '오늘 운동 일정이 있어요. 통기성 좋은 옷과 편한 신발로 준비할까요?';
    } else if (RegExp(r'데이트|소개팅|기념일|결혼식|약속').hasMatch(titles)) {
      asset = 'assets/characters/chakchak-date.png';
      colors = const [Color(0xFFD86685), Color(0xFFE9879D), Color(0xFFEFA8AE)];
      bubble = '오늘 데이트가 있네요. 편안하면서도 기분 좋은 포인트가 있는 코디는 어때요?';
    } else if (RegExp(r'피크닉|소풍|공원|나들이|놀이공원|해변|바다').hasMatch(titles)) {
      asset = 'assets/characters/chakchak-picnic.png';
    } else if (RegExp(r'출근|회사|업무|회의|미팅|면접|발표|세미나|오피스').hasMatch(titles)) {
      asset = 'assets/characters/chakchak-business.png';
      colors = const [Color(0xFF3D506F), Color(0xFF5D7191), Color(0xFF8495AD)];
      bubble = '오늘 일정에는 단정한 인상과 편안한 활동성을 함께 챙겨볼까요?';
    } else if (RegExp(r'공부|스터디|도서관|수업|강의|시험|과제|독서|학원').hasMatch(titles)) {
      asset = 'assets/characters/chakchak-study.png';
      colors = const [Color(0xFF59609B), Color(0xFF757DB3), Color(0xFF9DA3CA)];
      bubble = '오래 집중해도 편안하도록 부드러운 소재와 가벼운 겉옷을 추천할게요.';
    }
    final isRain = (weather?.weatherCode ?? 0) >= 50;
    if (isRain) {
      asset = 'assets/characters/chakchak-rain.png';
      colors = const [Color(0xFF466C8A), Color(0xFF6489A6), Color(0xFF8FB1C8)];
      bubble = '비 소식이 있어요. 우산과 물에 강한 신발을 챙기고 얇은 겉옷도 준비할까요?';
    }
    final temperature = weather?.temperature.round() ?? 28;
    final apparentTemperature = weather?.apparentTemperature.round() ?? 30;
    final humidity = weather?.humidity.round() ?? 48;
    final windSpeed = weather?.windSpeed.toStringAsFixed(1) ?? '2.0';
    final precipitation = weather?.precipitationProbability.round() ?? 0;
    final condition = isRain ? '비' : '맑음';
    return Container(
      height: heroHeight,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Column(children: [
        Row(children: [
          BrandMark(color: foreground),
          const Spacer(),
          IconButton(
              onPressed: loading ? null : onRefresh,
              tooltip: '날씨 새로고침',
              icon: loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh_rounded),
              color: Colors.white,
              style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: .16)))
        ]),
        const SizedBox(height: 8),
        Row(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.asset('assets/icons/map.svg',
              width: 17,
              height: 17,
              colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn)),
          const SizedBox(width: 5),
          Text(locationLabel,
              style: TextStyle(
                  color: foreground, fontWeight: FontWeight.w700, fontSize: 13))
        ]),
        const SizedBox(height: 10),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
            decoration: BoxDecoration(
                color: const Color(0xFFFFFDFA),
                borderRadius: BorderRadius.circular(18)
                    .copyWith(bottomLeft: const Radius.circular(5))),
            child: Text(bubble,
                style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.35))),
        Expanded(
            child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
              left: 3,
              top: 31,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatKoreanDate(DateTime.now()),
                        style: TextStyle(
                            color: foreground.withValues(alpha: .8),
                            fontSize: AppA11y.captionSize,
                            fontWeight: FontWeight.w600)),
                    Text('$temperature°',
                        style: TextStyle(
                            fontSize: 60,
                            height: .95,
                            fontWeight: FontWeight.w800,
                            color: foreground,
                            letterSpacing: -1)),
                    const SizedBox(height: 5),
                    Text('$condition · 체감 $apparentTemperature°',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: foreground,
                            fontSize: AppA11y.captionSize))
                  ])),
          Positioned(
              right: -13,
              bottom: -16,
              child: Image.asset(asset,
                  width: 202, height: 202, fit: BoxFit.contain)),
        ])),
        Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .16))),
            child: Row(children: [
              for (final stat in [
                ('체감', '$apparentTemperature°'),
                ('강수', '$precipitation%'),
                ('바람', '${windSpeed}m/s'),
                ('습도', '$humidity%')
              ])
                Expanded(
                    child: Column(children: [
                  Text(stat.$1,
                      style: TextStyle(
                          color: foreground.withValues(alpha: .72),
                          fontSize: AppA11y.captionSize)),
                  const SizedBox(height: 3),
                  Text(stat.$2,
                      style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                          fontSize: 13))
                ]))
            ])),
      ]),
    );
  }
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(formatKoreanDate(DateTime.now()),
                    style: const TextStyle(
                        fontSize: AppA11y.captionSize, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(ordered.isEmpty ? '등록된 일정 없음' : '${ordered.length}개의 일정',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15))
              ])),
          IconButton.filledTonal(
              onPressed: onAdd,
              tooltip: '일정 추가',
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: Colors.white)),
        ]),
        if (ordered.isEmpty)
          const Padding(
              padding: EdgeInsets.fromLTRB(0, 8, 0, 3),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('＋ 버튼을 눌러 오늘 일정을 추가해보세요.',
                      style: TextStyle(
                          fontSize: AppA11y.captionSize,
                          color: AppColors.muted))))
        else
          for (final item in ordered)
            Padding(
              padding: EdgeInsets.zero,
              child: Container(
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.line))),
                child: Row(children: [
                  SizedBox(
                      width: 50,
                      child: Text(item.time,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mintDark,
                              fontWeight: FontWeight.w800))),
                  Expanded(
                      child: Text(item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700))),
                  IconButton(
                      onPressed: () => onDelete(item.id),
                      tooltip: '${item.title} 삭제',
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.muted)),
                ]),
              ),
            ),
      ]),
    );
  }
}

class OutfitCard extends StatelessWidget {
  const OutfitCard(
      {super.key,
      required this.saved,
      required this.onSave,
      required this.onAskMate,
      required this.scheduleContext});
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onAskMate;
  final String scheduleContext;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 24,
                  offset: Offset(0, 9))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Pill(label: '오늘의 추천', color: AppColors.mintDark),
          const SizedBox(height: 16),
          Row(children: [
            for (final item in sampleGarments.take(3))
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: Semantics(
                          button: true,
                          label: '${item.name} 상세 보기',
                          child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          GarmentDetailScreen(item: item))),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.media),
                              child: GarmentVisual(item: item, size: 92)))))
          ]),
          const SizedBox(height: 14),
          const Text('린넨 셔츠와 블랙 슬랙스',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
          const SizedBox(height: 7),
          const Text('더운 날씨에도 가볍고, 오늘의 여러 일정을 소화하기 단정한 조합이에요.',
              style: TextStyle(color: AppColors.muted, height: 1.4)),
          const SizedBox(height: 15),
          Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(AppRadius.control)),
              child: Row(children: [
                const Icon(Icons.auto_awesome_rounded,
                    size: 17, color: AppColors.mintDark),
                const SizedBox(width: 7),
                Expanded(
                    child: Text(
                        scheduleContext.isEmpty
                            ? '28°의 더운 날씨와 편안한 하루를 고려했어요.'
                            : '28° 날씨와 $scheduleContext 일정을 고려했어요.',
                        style: const TextStyle(
                            fontSize: AppA11y.captionSize,
                            fontWeight: FontWeight.w600)))
              ])),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: FilledButton.icon(
                    onPressed: onSave,
                    icon: Icon(saved
                        ? Icons.check_rounded
                        : Icons.bookmark_add_outlined),
                    label: Text(saved ? '저장했어요' : '코디 저장'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        minimumSize: const Size.fromHeight(48)))),
            const SizedBox(width: 10),
            IconButton.filledTonal(
                onPressed: () {},
                tooltip: '다른 코디 보기',
                icon: const Icon(Icons.shuffle_rounded),
                style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: AppColors.mint,
                    foregroundColor: Colors.white))
          ]),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: onAskMate,
              icon: SvgPicture.asset('assets/icons/nav-mate.svg',
                  width: 20, height: 20),
              label: const Text('메이트에게 다른 코디 물어보기'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.line))),
        ]),
      );
}

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen(
      {super.key,
      required this.garments,
      required this.onAdd,
      required this.outfitSaved});
  final List<GarmentItem> garments;
  final VoidCallback onAdd;
  final bool outfitSaved;

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
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('내 옷장',
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  _Pill(
                      label: '${widget.garments.length}벌',
                      color: AppColors.ink),
                ]),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    hintText: '이름, 색상, 보관 위치 검색',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.mist,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SavedOutfitsScreen(
                          hasSavedOutfit: widget.outfitSaved))),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEDF9F5),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: const Color(0xFFDCE9E4))),
                    child: Row(children: [
                      SvgPicture.asset('assets/icons/heart.svg',
                          width: 28, height: 28),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('나의 코디',
                                style: TextStyle(
                                    fontSize: AppA11y.captionSize,
                                    color: AppColors.muted)),
                            Text('저장한 코디  ${widget.outfitSaved ? 1 : 0}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                          ])),
                      const Icon(Icons.chevron_right_rounded),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: appCategories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final value =
                          index == 0 ? '전체' : appCategories[index - 1];
                      return ChoiceChip(
                        label: Text(value),
                        labelStyle: TextStyle(
                            color:
                                filter == value ? Colors.white : AppColors.ink),
                        checkmarkColor: Colors.white,
                        selected: filter == value,
                        selectedColor: AppColors.mint,
                        onSelected: (_) => setState(() => filter = value),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(bottom: 82),
                    itemCount: visible.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: .79,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12),
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      return _WardrobeItem(
                        item: item,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    GarmentDetailScreen(item: item))),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 14,
            child: FloatingActionButton.extended(
              onPressed: widget.onAdd,
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('새 옷 등록'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WardrobeItem extends StatelessWidget {
  const _WardrobeItem({required this.item, required this.onTap});
  final GarmentItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: GarmentVisual(
                        item: item,
                        size: double.infinity,
                        fillUploadedPhoto: true)),
                const SizedBox(height: 9),
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  item.location.isEmpty
                      ? item.color
                      : '${item.color} · ${item.location}',
                  style: const TextStyle(
                      fontSize: AppA11y.captionSize,
                      color: AppColors.muted,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ),
      );
}

class GarmentDetailScreen extends StatelessWidget {
  const GarmentDetailScreen({super.key, required this.item});
  final GarmentItem item;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
            backgroundColor: AppColors.paper,
            surfaceTintColor: AppColors.paper,
            title: const Text('옷 상세')),
        body: Padding(
            padding: const EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                  child: SizedBox(
                      width: 230,
                      height: 260,
                      child: GarmentVisual(item: item, size: 230))),
              const SizedBox(height: 24),
              Text(item.name,
                  style: const TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 8,
                  children: [item.category, item.color, item.location]
                      .map((value) => Chip(
                          label: Text(value),
                          side: BorderSide.none,
                          backgroundColor: AppColors.mist))
                      .toList()),
              const SizedBox(height: 20),
              const Text('최근 14일 동안 입지 않았어요.',
                  style: TextStyle(color: Color(0xFF63706D))),
              const Spacer(),
              FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MateChatScreen(pinned: item))),
                  icon: const Icon(Icons.forum_rounded),
                  label: const Text('이 옷으로 코디 물어보기'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: AppColors.ink)),
            ])),
      );
}

class SavedOutfitsScreen extends StatelessWidget {
  const SavedOutfitsScreen({super.key, required this.hasSavedOutfit});
  final bool hasSavedOutfit;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
            backgroundColor: AppColors.paper,
            surfaceTintColor: AppColors.paper,
            title: const Text('저장한 코디')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: hasSavedOutfit
              ? ListView(children: [
                  const Text('오늘 추천에서 저장한 코디를 모아봤어요.',
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
                            const Text('8월 13일',
                                style: TextStyle(
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
                  Text('아직 저장한 코디가 없어요',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 7),
                  Text('오늘 화면의 코디 저장을 누르면\n이곳에 차곡차곡 모여요.',
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
      this.initialTab = 0,
      this.onWearOutfit});
  final List<GarmentItem> garments;
  final int initialTab;
  final VoidCallback? onWearOutfit;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late int tab;

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
                          for (final title in const [
                            '아이보리 셔츠와 네이비 데님',
                            '민트 가디건과 블랙 슬랙스',
                            '린넨 셔츠와 블랙 슬랙스'
                          ])
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
                                      const Text('지난 8월',
                                          style: TextStyle(
                                              fontSize: AppA11y.captionSize,
                                              color: AppColors.mintDark,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 5),
                                      Text(title,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 5),
                                      const Text('비슷한 날씨에 잘 입었던 조합이에요.',
                                          style: TextStyle(
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
                                    onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => GarmentDetailScreen(
                                                item: item))),
                                    leading: SizedBox(
                                        width: 62,
                                        height: 62,
                                        child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.media),
                                            child: GarmentVisual(
                                                item: item, size: 62))),
                                    title: Text(item.name,
                                        style: const TextStyle(fontWeight: FontWeight.w800)),
                                    subtitle: Text('${item.category} · ${item.color}\n30일 이상 쉬는 중'),
                                    isThreeLine: true,
                                    trailing: const Icon(Icons.chevron_right_rounded)))
                        ])),
            ])),
      );
}

class AddGarmentScreen extends StatefulWidget {
  const AddGarmentScreen({super.key, this.title = '새 옷 등록'});
  final String title;
  @override
  State<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends State<AddGarmentScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final colorController = TextEditingController();
  final locationController = TextEditingController();
  final categoryController = TextEditingController();
  final imagePicker = ImagePicker();
  String category = '상의';
  Uint8List? photoBytes;
  bool addingCategory = false;

  void _saveInlineCategory() {
    final next = categoryController.text.trim();
    if (next.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('카테고리 이름을 입력해주세요.')));
      return;
    }
    if (appCategories
        .any((value) => value.toLowerCase() == next.toLowerCase())) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미 있는 카테고리예요.')));
      return;
    }
    setState(() {
      appCategories.add(next);
      category = next;
      addingCategory = false;
      categoryController.clear();
    });
  }

  Future<void> _editCategory({String? current}) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(current == null ? '카테고리 추가' : '카테고리 이름 수정'),
              content: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 15,
                  decoration: const InputDecoration(
                      hintText: '예: 홈웨어', border: OutlineInputBorder())),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소')),
                FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pop(controller.text.trim()),
                    child: const Text('저장'))
              ],
            ));
    controller.dispose();
    if (result == null || result.isEmpty || !mounted) return;
    if (appCategories.any((value) =>
        value.toLowerCase() == result.toLowerCase() && value != current)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미 있는 카테고리예요.')));
      return;
    }
    setState(() {
      if (current == null) {
        appCategories.add(result);
      } else {
        appCategories[appCategories.indexOf(current)] = result;
      }
      category = result;
    });
  }

  Future<void> _deleteCategory(String value) async {
    if (appCategories.length == 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('카테고리는 하나 이상 필요해요.')));
      return;
    }
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text('$value 카테고리를 삭제할까요?'),
                content: const Text('이 카테고리의 기존 옷은 미분류로 표시돼요.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소')),
                  FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('삭제'))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() {
      appCategories.remove(value);
      if (category == value) category = appCategories.first;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    colorController.dispose();
    locationController.dispose();
    categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final photo = await imagePicker.pickImage(
          source: source, imageQuality: 82, maxWidth: 1200, maxHeight: 1200);
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => photoBytes = bytes);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진을 불러오지 못했어요. 사진 접근 권한을 확인해주세요.')));
    }
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

  void _save() {
    if (photoBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('옷 사진을 첨부해주세요.')));
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(GarmentItem(
      name: nameController.text.trim(),
      category: category,
      color: colorController.text.trim(),
      location: locationController.text.trim(),
      tone: const [
        Color(0xFFDFF4EC),
        Color(0xFFF8DFB5),
        Color(0xFFE6DDF5),
        Color(0xFFDCECF7),
        Color(0xFFF8DFE5),
        Color(0xFFE5EFD9)
      ][Random().nextInt(6)],
      imageBytes: photoBytes,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
            backgroundColor: AppColors.paper,
            surfaceTintColor: AppColors.paper,
            title: Text(widget.title)),
        body: SafeArea(
            child: Form(
                key: formKey,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  InkWell(
                    onTap: _selectPhotoSource,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 190,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.line)),
                      child: photoBytes == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(Icons.add_a_photo_outlined,
                                      size: 38, color: AppColors.mintDark),
                                  SizedBox(height: 8),
                                  Text('사진을 찍거나 앨범에서 고르기',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  SizedBox(height: 4),
                                  Text('JPG, PNG · 사진은 앱에서 최적화돼요.',
                                      style: TextStyle(
                                          fontSize: AppA11y.captionSize,
                                          color: AppColors.muted))
                                ])
                          : Stack(fit: StackFit.expand, children: [
                              Image.memory(photoBytes!, fit: BoxFit.contain),
                              const Positioned(
                                  right: 10,
                                  bottom: 10,
                                  child: Chip(
                                      label: Text('사진 변경'),
                                      avatar:
                                          Icon(Icons.edit_outlined, size: 17)))
                            ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      maxLength: 40,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? '옷 이름을 입력해주세요.'
                              : null,
                      decoration: const InputDecoration(
                          labelText: '옷 이름 *',
                          hintText: '예: 아이보리 린넨 셔츠',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  const Text('카테고리 *',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  Wrap(spacing: 7, runSpacing: 8, children: [
                    for (final value in appCategories)
                      Container(
                          decoration: BoxDecoration(
                              color: category == value
                                  ? AppColors.mint
                                  : Colors.white,
                              border: Border.all(
                                  color: category == value
                                      ? AppColors.mint
                                      : AppColors.line),
                              borderRadius: BorderRadius.circular(99)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            TextButton(
                                onPressed: () =>
                                    setState(() => category = value),
                                child: Text(value,
                                    style: TextStyle(
                                        color: category == value
                                            ? Colors.white
                                            : AppColors.ink))),
                            IconButton(
                                onPressed: () => _editCategory(current: value),
                                tooltip: '$value 이름 수정',
                                icon: Icon(Icons.edit_outlined,
                                    size: AppA11y.compactIconSize,
                                    color: category == value
                                        ? Colors.white
                                        : AppColors.ink)),
                            IconButton(
                                onPressed: () => _deleteCategory(value),
                                tooltip: '$value 삭제',
                                icon: Icon(Icons.close_rounded,
                                    size: AppA11y.compactIconSize,
                                    color: category == value
                                        ? Colors.white
                                        : const Color(0xFFB46B5E)))
                          ])),
                    IconButton.outlined(
                        onPressed: () => setState(() => addingCategory = true),
                        tooltip: '카테고리 추가',
                        icon: const Icon(Icons.add_rounded)),
                  ]),
                  if (addingCategory) ...[
                    const SizedBox(height: 9),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: categoryController,
                              autofocus: true,
                              maxLength: 15,
                              decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: '새 카테고리 이름',
                                  isDense: true,
                                  border: OutlineInputBorder()))),
                      const SizedBox(width: 6),
                      FilledButton(
                          onPressed: _saveInlineCategory,
                          child: const Text('저장')),
                      const SizedBox(width: 6),
                      OutlinedButton(
                          onPressed: () => setState(() {
                                addingCategory = false;
                                categoryController.clear();
                              }),
                          child: const Text('취소'))
                    ]),
                  ],
                  const SizedBox(height: 18),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                        child: TextFormField(
                            controller: colorController,
                            textInputAction: TextInputAction.next,
                            maxLength: 20,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? '색상을 입력해주세요.'
                                    : null,
                            decoration: const InputDecoration(
                                labelText: '색상 *',
                                hintText: '아이보리',
                                border: OutlineInputBorder()))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: TextFormField(
                            controller: locationController,
                            textInputAction: TextInputAction.done,
                            maxLength: 30,
                            onFieldSubmitted: (_) => _save(),
                            decoration: const InputDecoration(
                                labelText: '보관 위치 (선택)',
                                hintText: '안방 옷장',
                                border: OutlineInputBorder()))),
                  ]),
                  const SizedBox(height: 10),
                  FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          minimumSize: const Size.fromHeight(54)),
                      child: const Text('옷장에 저장하기')),
                ]))),
      );
}

class MateChatScreen extends StatefulWidget {
  const MateChatScreen({super.key, this.pinned, this.onExit, this.garments});
  final GarmentItem? pinned;
  final VoidCallback? onExit;
  final List<GarmentItem>? garments;

  @override
  State<MateChatScreen> createState() => _MateChatScreenState();
}

class _MateChatScreenState extends State<MateChatScreen> {
  final textController = TextEditingController();
  late List<ChatLine> lines;
  late List<GarmentItem> selectedGarments;
  final BackendService _backend = BackendService();
  bool _isReplying = false;

  @override
  void initState() {
    super.initState();
    lines = [
      ChatLine.mate(widget.pinned == null
          ? '오늘은 28°로 더워요. 오후 외부 미팅에 맞춰 가볍고 단정한 코디를 골라봤어요.'
          : '${widget.pinned!.name}을 꼭 입고 싶구나! 이 옷을 중심으로 코디해볼게요.')
    ];
    selectedGarments = (widget.garments ?? sampleGarments).take(3).toList();
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
      final wardrobe = widget.garments ?? sampleGarments;
      final response = await _backend.recommendOutfit(
        message: message,
        wardrobe: wardrobe
            .map((item) => {
                  'name': item.name,
                  'category': item.category,
                  'color': item.color,
                })
            .toList(),
        schedules: const [
          {'title': '오후 외부 미팅', 'time': '15:00'}
        ],
        weather: const {
          'temperature': 28,
          'condition': '맑음',
          'precipitationProbability': 10,
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
        selectedGarments = response.selectedItemNames
            .map((name) => byName[name])
            .whereType<GarmentItem>()
            .toList();
        if (selectedGarments.isEmpty) {
          selectedGarments = wardrobe.take(3).toList();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => lines.add(ChatLine.mate(_answerFor(message))));
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
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final quickPromptHeight = 64.0 + max(0.0, textScale - 1.0) * 20;
    return SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
          child: Row(children: [
            const _ChatbotAvatar(size: 48),
            const SizedBox(width: 10),
            const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('착착 메이트',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  Text('지금 코디를 같이 골라봐요',
                      style: TextStyle(
                          fontSize: AppA11y.captionSize,
                          color: AppColors.muted)),
                ]),
            const Spacer(),
            PopupMenuButton<String>(
              tooltip: '대화 메뉴',
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                if (value == 'reset') _resetChat();
                if (value == 'exit') _exitChat();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'reset', child: Text('대화 초기화')),
                PopupMenuItem(
                    value: 'exit',
                    child: Text('대화 나가기',
                        style: TextStyle(color: Color(0xFFA85B4E)))),
              ],
            ),
          ]),
        ),
        const Divider(height: 1, color: AppColors.line),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: lines.length + 1,
            itemBuilder: (context, index) {
              if (index == lines.length) {
                return MateOutfitSuggestion(items: selectedGarments);
              }
              return ChatBubble(line: lines[index]);
            },
          ),
        ),
        SizedBox(
          height: quickPromptHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            children: ['오늘 뭐 입지?', '조금 더 화사하게', '비 올 때 괜찮아?', '미팅에 맞춰줘']
                .map((value) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                          label: Text(value),
                          onPressed: _isReplying ? null : () => _send(value),
                          backgroundColor: AppColors.mist,
                          side: BorderSide.none),
                    ))
                .toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 13),
          decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line))),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: textController,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: '메이트에게 물어보기',
                  filled: true,
                  fillColor: AppColors.mist,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isReplying ? null : _send,
              tooltip: '메이트에게 질문 보내기',
              icon: _isReplying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.arrow_upward_rounded),
              style: IconButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white),
            ),
          ]),
        ),
      ]),
    );
  }
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
      child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  line.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!line.mine)
                  const Padding(
                      padding: EdgeInsets.only(right: 7),
                      child: _ChatbotAvatar(size: 34)),
                Flexible(
                    child: Container(
                        constraints: const BoxConstraints(maxWidth: 270),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                            color: line.mine ? AppColors.ink : AppColors.mist,
                            borderRadius: BorderRadius.circular(17).copyWith(
                                bottomLeft: line.mine
                                    ? const Radius.circular(17)
                                    : const Radius.circular(4),
                                bottomRight: line.mine
                                    ? const Radius.circular(4)
                                    : const Radius.circular(17))),
                        child: Text(line.text,
                            style: TextStyle(
                                color: line.mine ? Colors.white : AppColors.ink,
                                height: 1.38))))
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
  const MateOutfitSuggestion({super.key, required this.items});
  final List<GarmentItem> items;
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(left: 41, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('이 조합은 어때요?', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(children: [
          for (final item in items.take(3))
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GarmentVisual(item: item, size: 65)))
        ]),
        const SizedBox(height: 9),
        const Text('더운 날씨 + 외부 미팅',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.mintDark,
                fontWeight: FontWeight.w700))
      ]));
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen(
      {super.key, required this.onLogout, required this.onDeleteAccount});
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String displayName = '은지';
  final String email = 'eunji.style@gmail.com';
  Uint8List? profilePhotoBytes;
  int height = 165;
  int weight = 55;
  String faceTone = '뉴트럴';
  String region = '서울';
  bool calendarConnected = true;
  bool morningNotification = true;
  Set<String> styles = {'미니멀', '캐주얼'};

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
              const Text('내 정보 수정',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('착착에 표시되는 이름과 Google 계정 정보를 관리해요.',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: '이름',
                      filled: true,
                      border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextFormField(
                  initialValue: email,
                  readOnly: true,
                  decoration: const InputDecoration(
                      labelText: '이메일',
                      filled: true,
                      border: OutlineInputBorder())),
              const SizedBox(height: 14),
              FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    setState(() => displayName = name);
                    Navigator.of(sheetContext).pop();
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      minimumSize: const Size.fromHeight(52)),
                  child: const Text('내 정보 저장')),
              const Divider(height: 36),
              const Text('로그인 및 보안',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              const Text('Google 로그인 비밀번호는 Google에서 관리됩니다.',
                  style: TextStyle(
                      fontSize: AppA11y.captionSize, color: AppColors.muted)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(
                        text: 'https://myaccount.google.com/security'));
                    if (sheetContext.mounted)
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                          const SnackBar(
                              content: Text('Google 보안 설정 주소를 복사했어요.')));
                  },
                  icon: const Icon(Icons.password_rounded),
                  label: const Text('Google 비밀번호 변경 주소 복사'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50))),
              const Divider(height: 36),
              const Text('개인정보', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              const Text('착착이 처리하는 정보와 이용 목적, 보관 및 삭제 기준을 확인할 수 있어요.',
                  style: TextStyle(
                      fontSize: AppA11y.captionSize, color: AppColors.muted)),
              const SizedBox(height: 10),
              OutlinedButton(
                  onPressed: _showPrivacyPolicy,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                  child: const Text('개인정보 처리방침 보기')),
              const Divider(height: 36),
              const Text('회원 탈퇴',
                  style: TextStyle(
                      color: Color(0xFFB45142), fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              const Text('계정과 옷장·일정·맞춤 설정이 모두 삭제되고 재가입 시 온보딩부터 시작합니다.',
                  style: TextStyle(
                      fontSize: AppA11y.captionSize, color: AppColors.muted)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _deleteAccount();
                  },
                  icon: const Icon(Icons.person_remove_outlined),
                  label: const Text('착착 회원 탈퇴'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC65D4A),
                      minimumSize: const Size.fromHeight(50))),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
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
                        decoration: const InputDecoration(
                            labelText: '확인 문구',
                            hintText: '탈퇴',
                            border: OutlineInputBorder()))
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
                Text('수집 항목', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 5),
                Text(
                    'Google 계정의 이름·이메일·프로필 사진과 사용자가 입력한 신체 정보·옷장·일정·선호 스타일을 처리합니다.'),
                SizedBox(height: 16),
                Text('이용 목적', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 5),
                Text('로그인, 개인화된 코디 추천과 사용자 설정 유지 목적으로 이용합니다.'),
                SizedBox(height: 16),
                Text('보관 및 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 5),
                Text('로컬 데이터는 이 기기에 저장되며 회원 탈퇴 시 계정과 착착 데이터를 삭제합니다.'),
                SizedBox(height: 16),
                Text('외부 서비스', style: TextStyle(fontWeight: FontWeight.w800)),
                SizedBox(height: 5),
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

  Color _toneColor(String tone) => switch (tone) {
        '쿨톤' => const Color(0xFFEFD2C9),
        '웜톤' => const Color(0xFFD89C6C),
        '올리브' => const Color(0xFFB98B63),
        _ => const Color(0xFFDFB79B),
      };

  Future<void> _editBodyProfile() async {
    final heightController = TextEditingController(text: '$height');
    final weightController = TextEditingController(text: '$weight');
    var temporaryTone = faceTone;
    final result =
        await showModalBottomSheet<({int height, int weight, String tone})>(
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
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      const Text('핏과 색상 추천에만 사용하며 다른 사용자에게 공개하지 않아요.',
                          style: TextStyle(
                              fontSize: AppA11y.captionSize,
                              color: AppColors.muted)),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: TextField(
                                controller: heightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: '키',
                                    suffixText: 'cm',
                                    filled: true,
                                    border: OutlineInputBorder()))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: TextField(
                                controller: weightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: '몸무게',
                                    suffixText: 'kg',
                                    filled: true,
                                    border: OutlineInputBorder()))),
                      ]),
                      const SizedBox(height: 17),
                      const Text('얼굴톤',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['쿨톤', '뉴트럴', '웜톤', '올리브']
                              .map((tone) => ChoiceChip(
                                  avatar: CircleAvatar(
                                      radius: 7,
                                      backgroundColor: _toneColor(tone)),
                                  label: Text(tone),
                                  selected: temporaryTone == tone,
                                  onSelected: (_) => setSheetState(
                                      () => temporaryTone = tone)))
                              .toList()),
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
                            tone: temporaryTone
                          ));
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            minimumSize: const Size.fromHeight(54)),
                        child: const Text('저장하기'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50)),
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
        faceTone = result.tone;
      });
  }

  Future<void> _pickRegion() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      isScrollControlled: true,
      builder: (context) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('날씨 지역',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('오늘의 날씨를 확인할 지역을 선택하세요.',
                        style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop('내 위치'),
                        icon: SvgPicture.asset('assets/icons/map.svg',
                            width: 24, height: 24),
                        label: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('내 위치로 찾기')),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            foregroundColor: AppColors.mintDark,
                            side: const BorderSide(color: AppColors.mint))),
                    const SizedBox(height: 14),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: koreaRegions
                            .map((item) => ChoiceChip(
                                label: Text(item),
                                selected: item == region,
                                onSelected: (_) =>
                                    Navigator.of(context).pop(item)))
                            .toList()),
                    const SizedBox(height: 16),
                    OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50)),
                        child: const Text('취소')),
                  ])))),
    );
    if (result != null && mounted) setState(() => region = result);
  }

  Future<void> _pickStyles() async {
    var temporary = Set<String>.of(styles);
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('선호 스타일',
                        style: TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('여러 개를 선택할 수 있어요.',
                        style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 17),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['미니멀', '캐주얼', '모던', '클래식', '스트릿', '페미닌']
                            .map((item) => FilterChip(
                                label: Text(item),
                                selected: temporary.contains(item),
                                onSelected: (_) => setSheetState(() =>
                                    temporary.contains(item)
                                        ? temporary.remove(item)
                                        : temporary.add(item))))
                            .toList()),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: temporary.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(temporary),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            minimumSize: const Size.fromHeight(52)),
                        child: const Text('선택 저장')),
                    const SizedBox(height: 8),
                    OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50)),
                        child: const Text('취소')),
                  ]))),
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
        faceTone = '뉴트럴';
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
  Widget build(BuildContext context) => SafeArea(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: [
            const Text('마이페이지',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(AppRadius.card)),
                child: Row(children: [
                  Semantics(
                      button: true,
                      label:
                          profilePhotoBytes == null ? '프로필 사진 등록' : '프로필 사진 변경',
                      child: InkWell(
                          onTap: _pickProfilePhoto,
                          borderRadius: BorderRadius.circular(30),
                          child: Stack(clipBehavior: Clip.none, children: [
                            CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                backgroundImage: profilePhotoBytes == null
                                    ? null
                                    : MemoryImage(profilePhotoBytes!),
                                child: profilePhotoBytes == null
                                    ? Text(
                                        displayName.isEmpty
                                            ? '착'
                                            : displayName.substring(0, 1),
                                        style: const TextStyle(
                                            color: AppColors.mintDark,
                                            fontWeight: FontWeight.w800))
                                    : null),
                            const Positioned(
                                right: -2,
                                bottom: -2,
                                child: CircleAvatar(
                                    radius: 9,
                                    backgroundColor: AppColors.ink,
                                    child: Icon(Icons.add_rounded,
                                        size: 13, color: Colors.white)))
                          ]))),
                  const SizedBox(width: 12),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$displayName님',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(email,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xCCFFFFFF)))
                      ])
                ])),
            const SizedBox(height: 17),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Row(children: [
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('나의 신체 프로필',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 3),
                        Text('핏과 색상 추천에만 사용해요.',
                            style: TextStyle(
                                fontSize: AppA11y.captionSize,
                                color: AppColors.muted))
                      ])),
                  TextButton(
                      onPressed: _editBodyProfile, child: const Text('수정'))
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _BodyStat(label: '키', value: '$height cm')),
                  const SizedBox(width: 8),
                  Expanded(child: _BodyStat(label: '몸무게', value: '$weight kg')),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _BodyStat(
                          label: '얼굴톤',
                          value: faceTone,
                          color: _toneColor(faceTone)))
                ]),
              ]),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            _SettingGroup(title: '계정', children: [
              _SettingRow(label: '내 정보 수정', value: '', onTap: _editAccount),
            ]),
            const SizedBox(height: 16),
            OutlinedButton(
                onPressed: _resetPreferences,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: const Color(0xFF66736F),
                    side: const BorderSide(color: AppColors.line)),
                child: const Text('맞춤 설정 초기화')),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: const Color(0xFFA85B4E),
                    side: const BorderSide(color: Color(0xFFEADFDC))),
                child: const Text('로그아웃')),
          ]));
}

class _BodyStat extends StatelessWidget {
  const _BodyStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: AppColors.mist, borderRadius: BorderRadius.circular(13)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                fontSize: AppA11y.captionSize, color: AppColors.muted)),
        const SizedBox(height: 4),
        Row(children: [
          if (color != null) ...[
            CircleAvatar(radius: 6, backgroundColor: color),
            const SizedBox(width: 5)
          ],
          Flexible(
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)))
        ])
      ]));
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 9),
        Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(children: children))
      ]);
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(
      {this.icon,
      required this.label,
      required this.value,
      required this.onTap});
  final IconData? icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      onTap: onTap,
      leading: icon == null ? null : Icon(icon, color: AppColors.mintDark),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (value.isNotEmpty)
          ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 135),
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: AppA11y.captionSize, color: AppColors.muted))),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, color: Color(0xFF8A9390))
      ]));
}

class _ToggleSettingRow extends StatelessWidget {
  const _ToggleSettingRow(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        activeTrackColor: AppColors.mintDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );
}

class TodaySchedule {
  const TodaySchedule(
      {required this.id, required this.time, required this.title});
  final int id;
  final String time;
  final String title;
}

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet(
      {super.key, required this.initialSchedules, required this.onChanged});
  final List<TodaySchedule> initialSchedules;
  final ValueChanged<List<TodaySchedule>> onChanged;

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  late final List<TodaySchedule> schedules;
  final titleController = TextEditingController();
  TimeOfDay selectedTime = const TimeOfDay(hour: 15, minute: 0);

  @override
  void initState() {
    super.initState();
    schedules = List.of(widget.initialSchedules)
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _notify() => widget.onChanged(List.unmodifiable(schedules));

  void _addSchedule(String title, {String? time}) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;
    setState(() {
      schedules.add(TodaySchedule(
          id: DateTime.now().microsecondsSinceEpoch,
          time: time ?? _formatTime(selectedTime),
          title: cleanTitle));
      schedules.sort((a, b) => a.time.compareTo(b.time));
    });
    titleController.clear();
    _notify();
  }

  void _removeSchedule(int id) {
    setState(() => schedules.removeWhere((item) => item.id == id));
    _notify();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
        context: context, initialTime: selectedTime, helpText: '일정 시간 선택');
    if (picked != null && mounted) setState(() => selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    const quickSchedules = [
      ('09:00', '출근'),
      ('14:00', '외부 미팅'),
      ('19:00', '데이트'),
      ('18:00', '운동'),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          22, 0, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('오늘의 일정',
                          style: TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w800)),
                      SizedBox(height: 4),
                      Text('시간과 활동을 보고 코디를 추천해요.',
                          style: TextStyle(
                              fontSize: AppA11y.captionSize,
                              color: AppColors.muted))
                    ])),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('완료',
                        style: TextStyle(fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line)),
                child: schedules.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('아직 등록된 일정이 없어요.',
                            style: TextStyle(
                                fontSize: AppA11y.captionSize,
                                color: AppColors.muted)))
                    : Column(children: [
                        for (final item in schedules)
                          ListTile(
                            dense: true,
                            leading: SizedBox(
                                width: 45,
                                child: Text(item.time,
                                    style: const TextStyle(
                                        color: AppColors.mintDark,
                                        fontWeight: FontWeight.w800))),
                            title: Text(item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            trailing: IconButton(
                                onPressed: () => _removeSchedule(item.id),
                                tooltip: '${item.title} 삭제',
                                icon:
                                    const Icon(Icons.close_rounded, size: 19)),
                          ),
                      ]),
              ),
              const SizedBox(height: 17),
              const Text('빠른 추가',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickSchedules
                    .map((item) => ActionChip(
                        avatar: const Icon(Icons.add_rounded, size: 17),
                        label: Text(item.$2),
                        onPressed: () => _addSchedule(item.$2, time: item.$1)))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('＋ 내 일정 직접 작성',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mintDark,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 11),
                      Row(children: [
                        OutlinedButton.icon(
                            onPressed: _pickTime,
                            icon: const Icon(Icons.schedule_rounded, size: 18),
                            label: Text(_formatTime(selectedTime))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextField(
                                controller: titleController,
                                textInputAction: TextInputAction.done,
                                onSubmitted: _addSchedule,
                                decoration: const InputDecoration(
                                    hintText: '예: 성수동 전시 관람',
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide.none)))),
                        const SizedBox(width: 7),
                        IconButton.filled(
                            onPressed: () => _addSchedule(titleController.text),
                            tooltip: '일정 추가',
                            icon: const Icon(Icons.add_rounded),
                            style: IconButton.styleFrom(
                                backgroundColor: AppColors.ink,
                                foregroundColor: Colors.white)),
                      ]),
                    ]),
              ),
              const SizedBox(height: 14),
              const Divider(),
              const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_month_outlined),
                  title: Text('Google Calendar에서 가져오기'),
                  subtitle: Text('캘린더 읽기 권한을 별도로 요청해요.'),
                  trailing: Icon(Icons.chevron_right)),
            ]),
      ),
    );
  }
}

class ReDiscoveryRow extends StatelessWidget {
  const ReDiscoveryRow({super.key, required this.garments});
  final List<GarmentItem> garments;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: 160,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        _DiscoveryCard(
            color: const Color(0xFFE4DCF8),
            asset: 'assets/characters/chakchak-last-year.png',
            title: '작년 이맘때\n입었던 코디',
            subtitle: '8월의 기록 3개',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    DiscoveryScreen(garments: garments, initialTab: 0)))),
        const SizedBox(width: 12),
        _DiscoveryCard(
            color: const Color(0xFFFBE3B5),
            asset: 'assets/characters/chakchak-long-unworn.png',
            title: '오랫동안\n안 입은 옷',
            subtitle: '새롭게 조합해볼까요?',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    DiscoveryScreen(garments: garments, initialTab: 1)))),
      ]));
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
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 190,
            child: Stack(children: [
              const Positioned(
                  right: -18, top: 18, child: _DiscoveryCloud(scale: 1)),
              const Positioned(
                  left: -24, top: 64, child: _DiscoveryCloud(scale: .7)),
              Positioned(
                  right: -5,
                  top: 3,
                  child: IgnorePointer(
                      child: Image.asset(asset,
                          width: 118, height: 130, fit: BoxFit.contain))),
              Positioned(
                  left: 16,
                  right: 65,
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
      {super.key, required this.title, required this.trailing, this.onTap});
  final String title;
  final String trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(
            onPressed: onTap,
            child: Row(children: [
              Text(trailing,
                  style: const TextStyle(
                      fontSize: AppA11y.captionSize, color: AppColors.muted)),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted)
            ]))
      ]);
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.color = AppColors.ink});
  final Color color;
  @override
  Widget build(BuildContext context) => Text('착착',
      style: TextStyle(
          color: color,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: -1));
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
  const GoogleMark({super.key});
  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size.square(20), painter: _GoogleMarkPainter());
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.butt;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -.12, 1.75, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.63, 1.05, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.68, .82, false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.50, 1.05, false, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawLine(Offset(size.width * .53, size.height * .51),
        Offset(size.width * .91, size.height * .51), paint);
    canvas.drawLine(Offset(size.width * .89, size.height * .49),
        Offset(size.width * .89, size.height * .72), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class GarmentItem {
  const GarmentItem(
      {required this.name,
      required this.category,
      required this.color,
      required this.location,
      required this.tone,
      this.assetPath,
      this.imageBytes});
  final String name;
  final String category;
  final String color;
  final String location;
  final Color tone;
  final String? assetPath;
  final Uint8List? imageBytes;
}

const sampleGarments = [
  GarmentItem(
      name: '아이보리 린넨 셔츠',
      category: '상의',
      color: '아이보리',
      location: '안방 옷장',
      tone: Color(0xFFF2E8D5),
      assetPath: 'assets/garments/shirt-ivory-linen.png'),
  GarmentItem(
      name: '블랙 와이드 슬랙스',
      category: '하의',
      color: '블랙',
      location: '안방 옷장',
      tone: AppColors.ink,
      assetPath: 'assets/garments/pants-black-wide.png'),
  GarmentItem(
      name: '베이지 로퍼',
      category: '신발',
      color: '베이지',
      location: '신발장',
      tone: Color(0xFFC9A47B),
      assetPath: 'assets/garments/shoes-beige-loafers.png'),
  GarmentItem(
      name: '민트 가디건',
      category: '아우터',
      color: '민트',
      location: '서랍 2칸',
      tone: AppColors.mint,
      assetPath: 'assets/garments/cardigan-mint.png'),
  GarmentItem(
      name: '네이비 데님',
      category: '하의',
      color: '네이비',
      location: '안방 옷장',
      tone: Color(0xFF3E536D),
      assetPath: 'assets/garments/jeans-navy-straight.png'),
  GarmentItem(
      name: '화이트 스니커즈',
      category: '신발',
      color: '화이트',
      location: '신발장',
      tone: Color(0xFFF6F5F0),
      assetPath: 'assets/garments/shoes-white-sneakers.png'),
];

class GarmentVisual extends StatelessWidget {
  const GarmentVisual(
      {super.key,
      required this.item,
      required this.size,
      this.fillUploadedPhoto = false});
  final GarmentItem item;
  final double size;
  final bool fillUploadedPhoto;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: item.tone.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(16)),
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
                      child: Image.asset(item.assetPath!,
                          width: double.infinity,
                          height: double.infinity,
                          fit:
                              fillUploadedPhoto ? BoxFit.cover : BoxFit.contain,
                          semanticLabel: item.name)),
        ),
      );
}
