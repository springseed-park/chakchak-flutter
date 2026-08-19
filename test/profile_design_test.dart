import 'package:chakchak/design_system.dart';
import 'package:chakchak/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('마이페이지는 착착 타이포그래피와 surface 카드 체계를 사용한다', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ChakchakTheme.light(),
        home: Scaffold(
          body: ProfileScreen(
            accountDisplayName: '주원',
            accountEmail: 'juwon@example.com',
            initialHeight: 165,
            initialWeight: 55,
            initialGender: '여',
            onLogout: () async {},
            onDeleteAccount: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final title = tester.widget<Text>(find.text('마이페이지'));
    expect(title.style?.fontFamily, 'Paperlogy');
    expect(title.style?.fontSize, 20);
    expect(title.style?.fontWeight, FontWeight.w700);

    final summary = tester.widget<Container>(
      find.byKey(const Key('profile-summary-card')),
    );
    final decoration = summary.decoration! as BoxDecoration;
    expect(decoration.color, ChakchakColors.surface);
    expect(decoration.border, isNotNull);

    expect(find.text('추천 설정'), findsOneWidget);
    expect(find.text('Google Calendar'), findsOneWidget);
    expect(find.text('아침 코디 알림'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(ProfileScreen),
      matchesGoldenFile('goldens/profile-page.png'),
    );
  });
}
