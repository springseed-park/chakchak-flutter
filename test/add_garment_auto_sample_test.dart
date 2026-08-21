import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chakchak/main.dart';

void main() {
  test('민소매 크롭티 분석명은 여성 크롭 민소매 샘플로 연결된다', () {
    final sample = garmentSampleForDetectedStyle(
      category: '상의',
      detailCategory: '민소매크롭티',
      fit: '기본',
    );

    expect(sample, isNotNull);
    expect(sample!.detailCategory, '크롭 민소매');
    expect(
      sample.assetPath,
      'assets/garment_samples/female_tanktop_slim_cropped_sleeveless.png',
    );
  });

  test('이미 저장된 슬림 민소매도 탱크탑 샘플로 복구된다', () {
    const garment = GarmentItem(
      name: '화이트 민소매 상의',
      category: '상의',
      detailCategory: '민소매',
      fit: '슬림',
      color: '화이트',
      location: '',
      tone: Color(0xFFF2EEE4),
      registrationMethod: '착장 사진 AI 분석',
    );

    final sample = garmentSampleForDisplay(garment);
    expect(sample, isNotNull);
    expect(
      sample!.assetPath,
      'assets/garment_samples/female_tanktop_slim_cropped_sleeveless.png',
    );
  });

  testWidgets('AI로 저장된 빈 민소매 상세 화면은 탱크탑 샘플을 표시한다', (tester) async {
    const garment = GarmentItem(
      name: '화이트 민소매 상의',
      category: '상의',
      detailCategory: '민소매',
      fit: '슬림',
      color: '화이트',
      location: '',
      tone: Color(0xFFF2EEE4),
      tintColor: Color(0xFFF6F5F1),
      registrationMethod: '착장 사진 AI 분석',
    );

    await tester.pumpWidget(
      const MaterialApp(home: GarmentDetailScreen(item: garment)),
    );
    await tester.pumpAndSettle();

    final visual = tester.widget<ColorizedGarmentAsset>(
      find.byKey(const ValueKey('garment-recovered-sample')),
    );
    expect(
      visual.assetPath,
      'assets/garment_samples/female_tanktop_slim_cropped_sleeveless.png',
    );
  });

  testWidgets('세부 분류를 바꾸면 사진이 없을 때 기본 샘플도 바뀐다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddGarmentScreen()),
    );
    await tester.pumpAndSettle();

    var preview = tester.widget<ColorizedGarmentAsset>(
      find.byType(ColorizedGarmentAsset).first,
    );
    expect(
      preview.assetPath,
      'assets/garment_samples/unisex_tshirt_basic_shortsleeve.png.png',
    );

    await tester.tap(find.text('반팔티').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('긴팔티').last);
    await tester.pumpAndSettle();

    preview = tester.widget<ColorizedGarmentAsset>(
      find.byType(ColorizedGarmentAsset).first,
    );
    expect(
      preview.assetPath,
      'assets/garment_samples/unisex_tshirt_basic_longsleeve.png.png',
    );
  });

  testWidgets('직접 색상은 숫자 슬라이더 대신 그라데이션에서 고른다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AddGarmentScreen()),
    );
    await tester.pumpAndSettle();

    final customColorButton = find.byKey(const ValueKey('custom-color-button'));
    await tester.scrollUntilVisible(
      customColorButton,
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(customColorButton);
    await tester.pumpAndSettle();
    await tester.tap(customColorButton);
    await tester.pumpAndSettle();

    expect(find.text('색상 직접 선택'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-color-spectrum')), findsOneWidget);
    expect(find.text('색조'), findsNothing);
    expect(find.text('채도'), findsNothing);
    expect(find.text('밝기'), findsNothing);

    final spectrum = find.byKey(const ValueKey('custom-color-spectrum'));
    await tester.tapAt(tester.getTopLeft(spectrum) + const Offset(230, 62));
    await tester.pump();
    await tester.tap(find.text('선택'));
    await tester.pumpAndSettle();

    expect(find.text('색상 직접 선택'), findsNothing);
    expect(find.textContaining('선택한 색상: #'), findsOneWidget);
  });

  testWidgets('상세 화면에서 등록된 옷을 수정해 변경값을 전달한다', (tester) async {
    GarmentItem? updated;
    const garment = GarmentItem(
      name: '블랙 와이드 슬랙스',
      category: '하의',
      detailCategory: '와이드 슬랙스',
      color: '블랙',
      location: '안방 옷장',
      tone: Color(0xFFDFEDF6),
      assetPath: 'assets/garments/pants-black-wide.png',
    );

    await tester.pumpWidget(MaterialApp(
      home: GarmentDetailScreen(
        item: garment,
        onChanged: (item) => updated = item,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('하의 · 와이드 슬랙스'), findsOneWidget);
    expect(
      find.text('이 옷과 오늘 날씨·일정에 어울리는 다른 옷을 메이트가 찾아드릴게요.'),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('garment-detail-color')), findsOneWidget);
    expect(find.text('블랙'), findsNothing);
    expect(find.text('기본'), findsOneWidget);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    expect(find.text('옷 정보 수정'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '출근용 블랙 와이드 슬랙스');
    for (var index = 0; index < 5; index++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('수정 내용 저장하기'));
    await tester.pumpAndSettle();

    expect(updated?.name, '출근용 블랙 와이드 슬랙스');
  });

  testWidgets('새 옷에 슬림 기본 루즈 핏을 선택해 저장한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddGarmentScreen()));
    await tester.pumpAndSettle();

    final looseFit = find.byKey(const ValueKey('garment-fit-루즈'));
    await tester.scrollUntilVisible(
      looseFit,
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(looseFit);
    await tester.pump();

    final selected = tester.widget<Container>(
      find.descendant(of: looseFit, matching: find.byType(Container)).first,
    );
    final decoration = selected.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.mintDark);
  });

  testWidgets('옷 상세에서 즐겨찾기를 켜고 끔 수 있다', (tester) async {
    GarmentItem? updated;
    const garment = GarmentItem(
      id: 'favorite-target',
      name: '화이트 반팔티',
      category: '상의',
      detailCategory: '반팔티',
      color: '화이트',
      location: '',
      tone: Color(0xFFF2EEE4),
    );

    await tester.pumpWidget(MaterialApp(
      home: GarmentDetailScreen(
        item: garment,
        onChanged: (item) => updated = item,
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('garment-favorite-toggle')));
    await tester.pump();
    expect(updated?.stableId, 'favorite-target');
    expect(updated?.isFavorite, isTrue);

    await tester.tap(find.byKey(const ValueKey('garment-favorite-toggle')));
    await tester.pump();
    expect(updated?.isFavorite, isFalse);
  });

  testWidgets('옷 상세에서 확인 후 등록된 옷을 삭제한다', (tester) async {
    GarmentItem? deleted;
    const garment = GarmentItem(
      id: 'delete-target',
      name: '블랙 반팔티',
      category: '상의',
      detailCategory: '반팔티',
      color: '블랙',
      location: '',
      tone: Color(0xFFF2EEE4),
    );

    await tester.pumpWidget(MaterialApp(
      home: GarmentDetailScreen(
        item: garment,
        onDelete: (item) => deleted = item,
      ),
    ));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('garment-delete-button')));
    await tester.pumpAndSettle();
    expect(find.text('이 옷을 삭제할까요?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('garment-delete-confirm')));
    await tester.pumpAndSettle();
    expect(deleted?.stableId, 'delete-target');
  });
}
