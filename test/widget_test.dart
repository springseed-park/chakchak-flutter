import 'dart:async';

import 'package:chakchak/main.dart';
import 'package:chakchak/services/app_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('착착 랜딩 화면을 표시한다', (tester) async {
    await tester.pumpWidget(const ChakchakApp());
    await tester.pump();

    expect(
        find.text('내 옷으로,\n오늘의 코디가 착착.', findRichText: true), findsOneWidget);
    expect(find.text('Google로 시작하기'), findsOneWidget);
  });

  testWidgets('주요 로그인 버튼은 최소 터치 영역을 충족한다', (tester) async {
    await tester.pumpWidget(const ChakchakApp());
    await tester.pump();

    final googleButton = find.widgetWithText(FilledButton, 'Google로 시작하기');
    expect(googleButton, findsOneWidget);
    expect(tester.getSize(googleButton).height, greaterThanOrEqualTo(48));
  });

  testWidgets('글자 크기 200%에서도 첫 화면이 잘리지 않는다', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const ChakchakApp());
    await tester.pump();

    expect(find.text('Google로 시작하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('신규 사용자는 Google 계정 선택이 끝난 뒤 약관을 표시한다', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _ControlledAuth();
    await tester.pumpWidget(ChakchakApp(auth: auth));
    await tester.pump();

    final googleButton = find.text('Google로 시작하기');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();

    expect(auth.signInRequested, isTrue);
    expect(find.text('착착 가입 약관 동의'), findsNothing);

    auth.completeSignIn();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('착착 가입 약관 동의'), findsOneWidget);
    final phoneRect =
        tester.getRect(find.byKey(const ValueKey('portfolio-phone-frame')));
    final sheetRect = tester.getRect(find.byType(BottomSheet));
    expect(sheetRect.left, greaterThanOrEqualTo(phoneRect.left));
    expect(sheetRect.right, lessThanOrEqualTo(phoneRect.right));

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    await tester.tap(find.text('동의하고 가입하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('오늘의 날씨는\n어디를 기준으로 볼까요?'), findsOneWidget);
    expect(find.byKey(const ValueKey('portfolio-phone-frame')), findsOneWidget);
  });

  testWidgets('로그인 후 메인 화면이 휴대폰 크기에서 표시된다', (tester) async {
    tester.view.physicalSize = const Size(410, 830);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: MainShell(
        onLogout: () async {},
        onDeleteAccount: () async {},
      ),
    ));
    await tester.pump();

    expect(find.text('서울 성동구'), findsOneWidget);
    expect(find.text("TODAY'S PICK"), findsOneWidget);
    expect(find.text('메인'), findsOneWidget);
    final heroRect =
        tester.getRect(find.byKey(const ValueKey('home-weather-hero')));
    expect(heroRect.left, 0);
    expect(heroRect.right, 410);
    expect(heroRect.top, 0);
    expect(tester.takeException(), isNull);
  });
}

class _ControlledAuth implements AppAuth {
  final Completer<AppSignInResult> _signInCompleter = Completer();
  bool signInRequested = false;

  @override
  String? get currentUserId => null;

  void completeSignIn() => _signInCompleter
      .complete(const AppSignInResult(userId: 'new-user', isNewUser: true));

  @override
  Future<AppSignInResult> signInWithGoogle() {
    signInRequested = true;
    return _signInCompleter.future;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> deleteCurrentUser() async {}
}
