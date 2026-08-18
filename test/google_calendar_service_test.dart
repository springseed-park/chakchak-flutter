import 'package:chakchak/services/google_calendar_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('선택한 날짜의 Google Calendar 시간 일정과 종일 일정을 변환한다', () async {
    late Uri requestedUri;
    late Map<String, String> requestedHeaders;
    final service = GoogleCalendarService(
      client: MockClient((request) async {
        requestedUri = request.url;
        requestedHeaders = request.headers;
        return http.Response(
            '''
          {
            "items": [
              {
                "id": "meeting-1",
                "summary": "외부 미팅",
                "start": {"dateTime": "2026-08-18T14:30:00+09:00"}
              },
              {
                "id": "holiday-1",
                "summary": "휴가",
                "start": {"date": "2026-08-18"}
              }
            ]
          }
        ''',
            200,
            headers: {'content-type': 'application/json'});
      }),
    );

    final events = await service.loadEvents(
      accessToken: 'calendar-token',
      date: DateTime(2026, 8, 18),
    );

    expect(requestedUri.path, '/calendar/v3/calendars/primary/events');
    expect(requestedUri.queryParameters['singleEvents'], 'true');
    expect(requestedHeaders['authorization'], 'Bearer calendar-token');
    expect(events, hasLength(2));
    expect(events.first.title, '외부 미팅');
    expect(events.first.time, '14:30');
    expect(events.last.time, '종일');
  });

  test('Calendar API 비활성화 오류를 이해하기 쉬운 문구로 보여준다', () async {
    final service = GoogleCalendarService(
      client: MockClient((_) async => http.Response('{}', 403)),
    );

    expect(
      () => service.loadEvents(
        accessToken: 'calendar-token',
        date: DateTime(2026, 8, 18),
      ),
      throwsA(predicate(
          (error) => error.toString().contains('Google Calendar API가 활성화'))),
    );
  });
}
