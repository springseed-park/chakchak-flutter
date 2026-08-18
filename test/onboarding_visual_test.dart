import 'package:chakchak/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('온보딩 첫 단계 HTML 기준 시각 검증', (tester) async {
    await tester.binding.setSurfaceSize(const Size(372, 826));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Paperlogy'),
        home: OnboardingScreen(onDone: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OnboardingScreen),
      matchesGoldenFile('goldens/onboarding-step-1.png'),
    );
  });
}
