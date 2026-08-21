import 'package:chakchak/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('베이직 옷장은 기본 색상과 계절 아우터를 포함한 공용 아이템으로 구성된다', () {
    expect(starterBasicGarments, hasLength(31));
    expect(
        starterBasicGarments.map((item) => item.name),
        containsAll([
          '블랙 베이직 반팔티',
          '화이트 베이직 반팔티',
          '블랙 베이직 긴팔티',
          '화이트 베이직 긴팔티',
          '블랙 숏 패딩',
          '베이지 롱 패딩',
          '베이지 숏 코트',
          '카멜 롱 코트',
        ]));
    expect(starterBasicGarments.every((item) => item.colorizeAsset), isTrue);
    expect(maleStarterGarments, hasLength(10));
    expect(femaleStarterGarments, hasLength(10));
    expect(starterGarmentsForGender('남'), hasLength(41));
    expect(starterGarmentsForGender('여'), hasLength(41));
    expect(starterGarmentsForGender('남').take(31), starterBasicGarments);
    expect(starterGarmentsForGender('여').take(31), starterBasicGarments);
  });

  Future<void> openThirdStep(
      WidgetTester tester, ValueChanged<OnboardingResult> onDone) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Paperlogy'),
      home: OnboardingScreen(onDone: onDone),
    ));
    await tester.tap(find.text('다음'));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pump();
  }

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('3단계에서 신체 정보와 베이직 옷장 기본값을 저장한다', (tester) async {
    OnboardingResult? result;
    await openThirdStep(tester, (value) => result = value);

    expect(find.text('내 몸과 옷장 준비를\n마지막으로 알려주세요.'), findsOneWidget);
    expect(find.text('사진으로 첫 옷 등록하기'), findsNothing);
    expect(find.text('베이직 아이템으로 채우기'), findsOneWidget);
    expect(find.text('남'), findsOneWidget);
    expect(find.text('여'), findsOneWidget);
    expect(find.text('선택 안 함'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '168');
    await tester.enterText(find.byType(TextField).at(1), '58');
    await tester.tap(find.text('착착 시작하기'));
    await tester.pump();

    expect(result?.height, 168);
    expect(result?.weight, 58);
    expect(result?.gender, '선택 안 함');
    expect(result?.useBasicWardrobe, isTrue);
  });

  testWidgets('키와 몸무게를 비워도 나중에 입력하도록 온보딩을 완료한다', (tester) async {
    OnboardingResult? result;
    await openThirdStep(tester, (value) => result = value);

    expect(find.textContaining('선택 항목이에요'), findsNothing);
    await tester.tap(find.text('착착 시작하기'));
    await tester.pump();

    expect(result?.height, isNull);
    expect(result?.weight, isNull);
    expect(result?.gender, '선택 안 함');
    expect(result?.useBasicWardrobe, isTrue);
  });

  testWidgets('성별로 남자 베이직 아이템을 선택할 수 있다', (tester) async {
    OnboardingResult? result;
    await openThirdStep(tester, (value) => result = value);

    await tester.enterText(find.byType(TextField).at(0), '178');
    await tester.enterText(find.byType(TextField).at(1), '72');
    await tester.tap(find.byKey(const ValueKey('onboarding-gender-남')));
    await tester.pump();
    await tester.tap(find.text('착착 시작하기'));
    await tester.pump();

    expect(result?.gender, '남');
    expect(result?.useBasicWardrobe, isTrue);
  });

  testWidgets('직접 채우기를 선택하면 빈 옷장 설정으로 완료한다', (tester) async {
    OnboardingResult? result;
    await openThirdStep(tester, (value) => result = value);

    await tester.enterText(find.byType(TextField).at(0), '172');
    await tester.enterText(find.byType(TextField).at(1), '64');
    await tester.tap(find.text('내가 하나하나 채우기'));
    await tester.pump();
    await tester.tap(find.text('착착 시작하기'));
    await tester.pump();

    expect(result?.useBasicWardrobe, isFalse);
  });

  test('성별을 선택하지 않으면 공용 베이직 아이템만 채운다', () {
    expect(starterGarmentsForGender('선택 안 함'), starterBasicGarments);
  });
}
