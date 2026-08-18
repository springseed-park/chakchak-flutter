import 'package:chakchak/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('작년 이맘때 시연용 착장 기록을 제공한다', () {
    final records = demoLastYearOutfits(DateTime(2026, 8, 18));

    expect(records, hasLength(4));
    expect(records.every((record) => record.date.year == 2025), isTrue);
    expect(records.every((record) => record.garmentNames.length == 3), isTrue);
  });

  testWidgets('오늘의 픽은 최신순으로 보이고 검색과 4벌 가로 슬라이드를 지원한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final records = [
      SavedOutfitRecord(
        date: DateTime(2026, 8, 18),
        title: '오후 미팅 코디',
        description: '단정한 보스',
        garmentNames: sampleGarments.take(4).map((item) => item.name).toList(),
      ),
      SavedOutfitRecord(
        date: DateTime(2026, 8, 12),
        title: '여행 코디',
        description: '편안한 이동',
        garmentNames:
            sampleGarments.skip(1).take(3).map((item) => item.name).toList(),
      ),
    ];

    await tester.pumpWidget(MaterialApp(
      home: SavedOutfitsScreen(
        hasSavedOutfit: true,
        records: records,
        garments: sampleGarments,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('2026년 8월 18일 화요일'), findsOneWidget);
    expect(find.text('2026년 8월 12일 수요일'), findsOneWidget);
    expect(find.byKey(const ValueKey('saved-outfit-horizontal-gallery')),
        findsOneWidget);
    expect(tester.getTopLeft(find.text('오후 미팅 코디')).dy,
        lessThan(tester.getTopLeft(find.text('여행 코디')).dy));

    await tester.enterText(find.byType(TextField), '여행');
    await tester.pump();

    expect(find.text('여행 코디'), findsOneWidget);
    expect(find.text('오후 미팅 코디'), findsNothing);
  });
}
