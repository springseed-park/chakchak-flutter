import 'dart:convert';
import 'dart:typed_data';

import 'package:chakchak/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('GarmentItem JSON round-trip preserves stable ID and cropped bytes', () {
    final original = GarmentItem(
      id: 'garment-test-1',
      name: '착장 사진 블랙 반팔티',
      category: '상의',
      detailCategory: '반팔티',
      fit: '기본',
      color: '블랙',
      location: '안방 옷장',
      tone: const Color(0xFFE8ECEA),
      imageBytes: Uint8List.fromList([0, 1, 2, 127, 255]),
      tintColor: const Color(0xFF202124),
      colorizeAsset: true,
      isFavorite: true,
      purchaseDate: DateTime(2026, 8, 20),
      registrationMethod: '착장 사진 AI 분석',
      lastWornLabel: '오늘 착용',
    );

    final restored = GarmentItem.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );

    expect(restored.stableId, 'garment-test-1');
    expect(restored.name, original.name);
    expect(restored.imageBytes, orderedEquals(original.imageBytes!));
    expect(restored.tintColor?.toARGB32(), original.tintColor?.toARGB32());
    expect(restored.purchaseDate, original.purchaseDate);
    expect(restored.registrationMethod, original.registrationMethod);
    expect(restored.lastWornLabel, original.lastWornLabel);
    expect(restored.isFavorite, isTrue);
  });

  test('legacy garment and saved-outfit JSON remain readable', () {
    const legacyGarment = GarmentItem(
      name: '기존 화이트 반팔티',
      category: '상의',
      detailCategory: '반팔티',
      color: '화이트',
      location: '',
      tone: Color(0xFFF2EEE4),
    );
    final firstId = legacyGarment.stableId;
    final restoredGarment = GarmentItem.fromJson(legacyGarment.toJson());
    final legacyOutfit = SavedOutfitRecord.fromJson({
      'date': '2026-08-20T00:00:00.000',
      'title': '기존 코디',
      'description': '이름으로 저장된 기록',
      'garmentNames': [legacyGarment.name],
    });

    expect(restoredGarment.stableId, firstId);
    expect(legacyOutfit.garmentNames, [legacyGarment.name]);
    expect(legacyOutfit.garmentIds, isEmpty);
  });

  testWidgets('MainShell restores an account-scoped wardrobe after restart',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const restored = GarmentItem(
      id: 'restored-garment-id',
      name: '재시작 후 복원된 바람막이',
      category: '아우터',
      detailCategory: '바람막이',
      color: '네이비',
      location: '현관',
      tone: Color(0xFFE5EFF7),
    );
    SharedPreferences.setMockInitialValues({
      'chakchak.wardrobe.items.v1.user-123': jsonEncode([restored.toJson()]),
    });

    await tester.pumpWidget(MaterialApp(
      home: MainShell(
        accountUserId: 'user-123',
        initialIndex: 1,
        initialGarments: const [],
        onLogout: () async {},
        onDeleteAccount: () async {},
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(restored.name), findsOneWidget);
  });

  testWidgets('saved outfits resolve stable IDs before legacy names',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const renamed = GarmentItem(
      id: 'stable-renamed-item',
      name: '수정된 라이트 블루 데님 셔츠',
      category: '상의',
      detailCategory: '데님 셔츠',
      color: '라이트 블루',
      location: '',
      tone: Color(0xFFE5EFF7),
    );
    final record = SavedOutfitRecord(
      date: DateTime(2026, 8, 20),
      title: '이름이 바뀐 옷 코디',
      description: 'ID로 연결해요.',
      garmentNames: const ['수정 전 이름'],
      garmentIds: const ['stable-renamed-item'],
    );

    await tester.pumpWidget(MaterialApp(
      home: SavedOutfitsScreen(
        hasSavedOutfit: true,
        records: [record],
        garments: const [renamed],
      ),
    ));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('saved-outfit-garment-수정된 라이트 블루 데님 셔츠')),
      findsOneWidget,
    );
  });
}
