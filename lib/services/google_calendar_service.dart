import 'dart:convert';

import 'package:http/http.dart' as http;

class GoogleCalendarEvent {
  const GoogleCalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
  });

  final String id;
  final String title;
  final DateTime date;
  final String time;
}

class GoogleCalendarService {
  GoogleCalendarService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<GoogleCalendarEvent>> loadEvents({
    required String accessToken,
    required DateTime date,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final nextDay = day.add(const Duration(days: 1));
    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events',
      {
        'timeMin': day.toUtc().toIso8601String(),
        'timeMax': nextDay.toUtc().toIso8601String(),
        'singleEvents': 'true',
        'orderBy': 'startTime',
        'maxResults': '100',
      },
    );
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw StateError(_errorMessage(response.statusCode, response.body));
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rawItems = payload['items'];
    if (rawItems is! List) return const [];
    final events = <GoogleCalendarEvent>[];
    for (final raw in rawItems.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final start = item['start'];
      if (start is! Map) continue;
      final startMap = Map<String, dynamic>.from(start);
      final dateTimeText = startMap['dateTime'] as String?;
      final allDayText = startMap['date'] as String?;
      final startDate = dateTimeText == null
          ? DateTime.tryParse(allDayText ?? '')
          : DateTime.tryParse(dateTimeText)?.toLocal();
      if (startDate == null) continue;
      final title = (item['summary'] as String?)?.trim();
      events.add(GoogleCalendarEvent(
        id: item['id'] as String? ?? '${startDate.toIso8601String()}-$title',
        title: title == null || title.isEmpty ? '제목 없는 일정' : title,
        date: DateTime(startDate.year, startDate.month, startDate.day),
        time: dateTimeText == null
            ? '종일'
            : '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}',
      ));
    }
    return events;
  }

  String _errorMessage(int statusCode, String body) {
    if (statusCode == 401) return 'Google Calendar 권한이 만료됐어요. 다시 연결해주세요.';
    if (statusCode == 403) {
      return 'Google Calendar API가 활성화되어 있는지, 캘린더 읽기 권한에 동의했는지 확인해주세요.';
    }
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      final error = payload['error'];
      if (error is Map && error['message'] is String) {
        return 'Google Calendar를 불러오지 못했어요: ${error['message']}';
      }
    } catch (_) {
      // Google의 비 JSON 오류 응답은 아래 공통 메시지로 처리합니다.
    }
    return 'Google Calendar를 불러오지 못했어요. (오류 $statusCode)';
  }
}
