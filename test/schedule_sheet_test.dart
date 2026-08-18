import 'package:chakchak/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('선택한 날짜에서 직접 입력한 일정을 저장한다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    List<TodaySchedule>? savedSchedules;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScheduleSheet(
          initialSchedules: const [
            TodaySchedule(id: 1, time: '09:00', title: '출근'),
            TodaySchedule(id: 2, time: '14:00', title: '외부 미팅'),
          ],
          onChanged: (value) => savedSchedules = value,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('선택한 날짜의 일정'), findsOneWidget);
    expect(find.text('빠른 추가'), findsNothing);
    expect(find.textContaining('에 일정 추가'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_outlined), findsWidgets);
    expect(find.textContaining('Google Calendar 가져오기'), findsOneWidget);
    expect(find.text('일정 저장하기'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '성수동 전시 관람');
    await tester.tap(find.byTooltip('일정 추가'));
    await tester.pumpAndSettle();
    expect(savedSchedules, isNull);
    expect(find.text('성수동 전시 관람'), findsOneWidget);

    await tester.tap(find.text('일정 저장하기'));
    await tester.pumpAndSettle();
    expect(savedSchedules, isNotNull);
    final added =
        savedSchedules!.singleWhere((item) => item.title == '성수동 전시 관람');
    expect(DateUtils.isSameDay(added.effectiveDate, DateTime.now()), isTrue);
  });

  testWidgets('날짜를 바꾸면 해당 날짜 일정만 보이고 Google 일정을 합친다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final today = DateUtils.dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));
    DateTime? importedDate;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScheduleSheet(
          initialSchedules: [
            TodaySchedule(id: 1, time: '09:00', title: '오늘 일정', date: today),
            TodaySchedule(id: 2, time: '11:00', title: '내일 일정', date: tomorrow),
          ],
          onImportGoogleCalendar: (date) async {
            importedDate = date;
            return [
              TodaySchedule(id: 3, time: '16:00', title: '구글 미팅', date: date),
            ];
          },
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('오늘 일정'), findsOneWidget);
    expect(find.text('내일 일정'), findsNothing);

    await tester.tap(find.byTooltip('다음 날짜'));
    await tester.pumpAndSettle();
    expect(find.text('오늘 일정'), findsNothing);
    expect(find.text('내일 일정'), findsOneWidget);

    await tester.tap(find.textContaining('Google Calendar 가져오기'));
    await tester.pumpAndSettle();
    expect(DateUtils.isSameDay(importedDate, tomorrow), isTrue);
    expect(find.text('구글 미팅'), findsOneWidget);
  });
}
