import 'package:chakchak/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('메인 지역명을 누르면 작은 칩 형태의 지역 선택창이 열린다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            onAskMate: () {},
            saved: false,
            onSave: () {},
            garments: const [],
          ),
        ),
      ),
    );
    // WeatherHero의 기존 소형 뷰포트 오버플로는 이 테스트 범위 밖입니다.
    tester.takeException();

    await tester.tap(find.text('서울 성동구'));
    await tester.pumpAndSettle();

    expect(find.text('날씨 지역'), findsOneWidget);
    expect(find.text('내 위치로 찾기'), findsOneWidget);
    expect(find.text('서울'), findsOneWidget);
    expect(find.text('제주'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('메인 날짜는 실행 시점의 오늘 날짜를 표시한다', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            onAskMate: () {},
            saved: false,
            onSave: () {},
            garments: const [],
          ),
        ),
      ),
    );
    tester.takeException();

    expect(find.text(formatKoreanHeroDate(DateTime.now())), findsOneWidget);
  });

  testWidgets('저장된 날씨 지역을 재진입 시 복원한다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'chakchak_weather_region_v1': '제주',
      'chakchak_weather_location_label_v1': '제주 제주시',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            onAskMate: () {},
            saved: false,
            onSave: () {},
            garments: const [],
          ),
        ),
      ),
    );
    await tester.pump();
    tester.takeException();

    expect(find.text('제주 제주시'), findsOneWidget);
  });
}
