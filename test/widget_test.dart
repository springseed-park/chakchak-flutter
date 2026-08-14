import 'package:chakchak/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('착착 랜딩 화면을 표시한다', (tester) async {
    await tester.pumpWidget(const ChakchakApp());
    await tester.pump();

    expect(
        find.text('내 옷으로,\n오늘의 코디가 착착.', findRichText: true), findsOneWidget);
    expect(find.text('Google로 시작하기'), findsOneWidget);
  });
}
