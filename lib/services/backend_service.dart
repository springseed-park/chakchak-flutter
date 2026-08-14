import 'package:cloud_functions/cloud_functions.dart';

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

  Future<WeatherSnapshot> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    final result = await _functions.httpsCallable('getKmaWeather').call({
      'latitude': latitude,
      'longitude': longitude,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
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
