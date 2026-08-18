import 'package:chakchak/main.dart';
import 'package:chakchak/services/backend_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('메이트는 밝은 화면에서 실제 날씨와 일정 문구를 보여준다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<GarmentItem>? selectedOutfit;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MateChatScreen(
          garments: starterBasicGarments,
          schedules: [
            TodaySchedule(
              id: 1,
              time: '19:00',
              title: '데이트',
              date: DateTime.now(),
            ),
          ],
          weather: const WeatherSnapshot(
            temperature: 22,
            apparentTemperature: 22,
            humidity: 50,
            windSpeed: 1,
            precipitationProbability: 10,
            weatherCode: 0,
            sourceLabel: '테스트',
          ),
          onUseOutfit: (items) => selectedOutfit = items,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('착착 메이트'), findsOneWidget);
    expect(find.textContaining('오늘은 22°'), findsOneWidget);
    expect(find.textContaining('데이트'), findsOneWidget);
    expect(find.text('이 조합은 어때요?'), findsOneWidget);
    expect(find.text('오늘의 코디로 보기'), findsOneWidget);
    expect(find.text('오늘 뭐 입지?'), findsOneWidget);
    expect(find.text('메이트에게 물어보기'), findsOneWidget);

    final coloredBoxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
    expect(coloredBoxes.any((box) => box.color == AppColors.paper), isTrue);
    await tester.tap(find.byKey(const ValueKey('mate-use-outfit-button')));
    expect(selectedOutfit, isNotNull);
    expect(selectedOutfit, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('옷장에서 선택한 옷을 메이트 조합에 반드시 포함한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pinned =
        starterBasicGarments.firstWhere((item) => item.name == '라이트 블루 데님 셔츠');
    List<GarmentItem>? selectedOutfit;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MateChatScreen(
          pinned: pinned,
          garments: starterBasicGarments,
          onUseOutfit: (items) => selectedOutfit = items,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining(pinned.name), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is GarmentVisual && widget.item.name == pinned.name),
      findsWidgets,
    );
    await tester.tap(find.byKey(const ValueKey('mate-use-outfit-button')));
    expect(selectedOutfit!.map((item) => item.name), contains(pinned.name));
    expect(tester.takeException(), isNull);
  });
}
