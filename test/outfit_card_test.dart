import 'package:chakchak/main.dart';
import 'package:chakchak/services/backend_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('투데이스 픽을 플랫레이로 보여주고 오늘의 픽으로 선택한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var selectCount = 0;
    var saved = false;
    var variation = 0;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: OutfitCard(
                saved: saved,
                onSave: () {
                  setState(() => saved = !saved);
                  selectCount += 1;
                },
                onAskMate: () {},
                garments: starterBasicGarments,
                scheduleContext: '14:00 외부 미팅',
                variationIndex: variation,
                onRefresh: () => setState(() => variation += 1),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('today-editorial-flatlay')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('today-outfit-화이트 베이직 반팔티')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('today-outfit-블랙 와이드 슬랙스')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('today-outfit-베이지 베이직 가디건')), findsNothing);
    expect(
        find.byKey(const ValueKey('today-outfit-화이트 베이직 긴팔티')), findsNothing);
    expect(find.byKey(const ValueKey('today-outfit-블랙 베이직 긴팔티')), findsNothing);
    expect(
        find.byKey(const ValueKey('today-outfit-블랙 클래식 로퍼')), findsOneWidget);
    expect(find.text('오늘의 픽으로 선택'), findsOneWidget);
    expect(find.byKey(const ValueKey('today-outfit-refresh')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('오늘의 픽으로 선택'));
    await tester.tap(find.text('오늘의 픽으로 선택'));
    await tester.pumpAndSettle();
    expect(selectCount, 1);
    expect(find.text('오늘의 픽으로 선택했어요'), findsOneWidget);

    await tester.tap(find.text('오늘의 픽으로 선택했어요'));
    await tester.pumpAndSettle();
    expect(selectCount, 2);
    expect(find.text('오늘의 픽으로 선택'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('today-outfit-refresh')));
    await tester.pumpAndSettle();
    expect(variation, 1);
    expect(
        find.byKey(const ValueKey('today-editorial-flatlay')), findsOneWidget);
  });

  testWidgets('오늘 코디는 고정 샘플이 아니라 전달된 옷장을 사용한다', (tester) async {
    const customTop = GarmentItem(
      name: '나의 파란 반팔티',
      category: '상의',
      detailCategory: '반팔티',
      color: '블루',
      location: '',
      tone: Color(0xFFDDEEFF),
      assetPath:
          'assets/garment_samples/unisex_tshirt_basic_shortsleeve.png.png',
    );
    const customBottom = GarmentItem(
      name: '나의 데님 바지',
      category: '하의',
      detailCategory: '스트레이트 데님',
      color: '라이트 블루',
      location: '',
      tone: Color(0xFFDDEEFF),
      assetPath:
          'assets/garment_samples/unisex_jeans_straight_lightblue_denim.png',
    );
    const customShoes = GarmentItem(
      name: '나의 화이트 스니커즈',
      category: '신발',
      detailCategory: '로우탑 스니커즈',
      color: '화이트',
      location: '',
      tone: Color(0xFFF1F2EE),
      assetPath: 'assets/garment_samples/unisex_shoes_sneakers_lowtop.png',
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OutfitCard(
            saved: false,
            onSave: _noop,
            onAskMate: _noop,
            garments: [customTop, customBottom, customShoes],
            scheduleContext: '주말 산책',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('today-outfit-나의 파란 반팔티')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-outfit-나의 데님 바지')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('today-outfit-나의 화이트 스니커즈')), findsOneWidget);
  });

  testWidgets('22도 데이트에는 화사한 원피스 코디를 우선한다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OutfitCard(
            saved: false,
            onSave: _noop,
            onAskMate: _noop,
            garments: starterGarmentsForGender('여'),
            scheduleContext: '19:00 데이트',
            weather: WeatherSnapshot(
              temperature: 22,
              apparentTemperature: 22,
              humidity: 50,
              windSpeed: 1,
              precipitationProbability: 10,
              weatherCode: 0,
              sourceLabel: '테스트',
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('today-outfit-코랄 A라인 미디 원피스')),
      findsOneWidget,
    );
    expect(find.textContaining('코랄 A라인'), findsOneWidget);
  });

  testWidgets('메이트가 고른 조합을 메인 오늘의 코디에 그대로 표시한다', (tester) async {
    final selected = [
      starterBasicGarments.firstWhere((item) => item.name == '라이트 블루 데님 셔츠'),
      starterBasicGarments.firstWhere((item) => item.name == '블랙 와이드 슬랙스'),
      starterBasicGarments.firstWhere((item) => item.name == '블랙 클래식 로퍼'),
    ];

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OutfitCard(
            saved: false,
            onSave: _noop,
            onAskMate: _noop,
            garments: starterBasicGarments,
            mateSelectedOutfit: selected,
            scheduleContext: '외부 미팅',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    for (final item in selected) {
      expect(find.byKey(ValueKey('today-outfit-${item.name}')), findsOneWidget);
    }
    expect(find.text('메이트와 함께 고른 오늘의 코디예요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
