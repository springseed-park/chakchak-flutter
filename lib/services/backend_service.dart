import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MateRecommendation {
  const MateRecommendation({
    required this.answer,
    required this.selectedItemNames,
  });

  final String answer;
  final List<String> selectedItemNames;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.sourceLabel,
  });

  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double windSpeed;
  final double precipitationProbability;
  final int weatherCode;
  final String sourceLabel;
}

class BackendService {
  BackendService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  final FirebaseFunctions _functions;

  Future<void> deleteMyData() async {
    await _functions.httpsCallable('deleteMyData').call();
  }

  Future<MateRecommendation> recommendOutfit({
    required String message,
    required List<Map<String, Object?>> wardrobe,
    required List<Map<String, Object?>> schedules,
    required Map<String, Object?> weather,
    List<Map<String, String>> history = const [],
  }) async {
    if (_isLocalWebPreview) {
      try {
        return await _getLocalMateRecommendation(
          message: message,
          wardrobe: wardrobe,
          schedules: schedules,
          weather: weather,
          history: history,
        );
      } catch (_) {
        // Fall through to Firebase so a running emulator/deployed callable can
        // still serve the preview when the local proxy is unavailable.
      }
    }
    final result = await _functions.httpsCallable('recommendOutfit').call({
      'message': message,
      'context': {
        'wardrobe': wardrobe,
        'schedules': schedules,
        'weather': weather,
      },
      'history': history,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return MateRecommendation(
      answer: data['answer'] as String? ?? '조건에 맞는 코디를 다시 골랐어요.',
      selectedItemNames: (data['selectedItems'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  Future<MateRecommendation> _getLocalMateRecommendation({
    required String message,
    required List<Map<String, Object?>> wardrobe,
    required List<Map<String, Object?>> schedules,
    required Map<String, Object?> weather,
    required List<Map<String, String>> history,
  }) async {
    final response = await http
        .post(
          Uri.http('127.0.0.1:4173', '/api/mate'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            'context': {
              'wardrobe': wardrobe,
              'schedules': schedules,
              'weather': weather,
            },
            'history': history,
          }),
        )
        .timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) {
      throw StateError('로컬 AI 메이트 오류 (${response.statusCode})');
    }
    final data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return MateRecommendation(
      answer: data['answer'] as String? ?? '조건에 맞는 코디를 다시 골랐어요.',
      selectedItemNames: (data['selectedItems'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  Future<WeatherSnapshot> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    if (_isLocalWebPreview) {
      try {
        return await _getLocalWeather(
          latitude: latitude,
          longitude: longitude,
        );
      } catch (_) {
        return _getOpenMeteoWeather(
          latitude: latitude,
          longitude: longitude,
        );
      }
    }

    try {
      final result = await _functions.httpsCallable('getKmaWeather').call({
        'latitude': latitude,
        'longitude': longitude,
      });
      return _weatherFromMap(Map<String, dynamic>.from(result.data as Map));
    } catch (_) {
      return _getOpenMeteoWeather(
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  bool get _isLocalWebPreview {
    if (!kIsWeb) return false;
    return Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1';
  }

  Future<WeatherSnapshot> _getLocalWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.http('127.0.0.1:4173', '/api/weather', {
      'latitude': '$latitude',
      'longitude': '$longitude',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('로컬 날씨 서버 오류 (${response.statusCode})');
    }
    return _weatherFromMap(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<WeatherSnapshot> _getOpenMeteoWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
      'hourly': 'precipitation_probability',
      'wind_speed_unit': 'ms',
      'timezone': 'Asia/Seoul',
      'forecast_days': '1',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('날씨 조회 오류 (${response.statusCode})');
    }
    final payload = Map<String, dynamic>.from(
      jsonDecode(response.body) as Map,
    );
    final current = Map<String, dynamic>.from(payload['current'] as Map);
    final hourly = Map<String, dynamic>.from(payload['hourly'] as Map? ?? {});
    final currentTime = current['time']?.toString() ?? '';
    final currentHour =
        currentTime.length >= 13 ? currentTime.substring(0, 13) : currentTime;
    final times = (hourly['time'] as List<dynamic>? ?? const []);
    final index = times.indexWhere(
      (time) => time.toString().startsWith(currentHour),
    );
    final probabilities =
        hourly['precipitation_probability'] as List<dynamic>? ?? const [];
    return WeatherSnapshot(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0,
      apparentTemperature:
          (current['apparent_temperature'] as num?)?.toDouble() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      precipitationProbability: index >= 0 && index < probabilities.length
          ? (probabilities[index] as num?)?.toDouble() ?? 0
          : 0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      sourceLabel: 'Open-Meteo',
    );
  }

  WeatherSnapshot _weatherFromMap(Map<String, dynamic> data) {
    double number(String key) => (data[key] as num?)?.toDouble() ?? 0;
    return WeatherSnapshot(
      temperature: number('temperature'),
      apparentTemperature: number('apparentTemperature'),
      humidity: number('humidity'),
      windSpeed: number('windSpeed'),
      precipitationProbability: number('precipitationProbability'),
      weatherCode: (data['code'] as num?)?.toInt() ?? 0,
      sourceLabel: data['sourceLabel'] as String? ?? '기상청 단기예보',
    );
  }
}
