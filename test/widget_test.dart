import 'package:chakchak/main.dart';
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
}
