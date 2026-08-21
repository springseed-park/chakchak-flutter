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

class NormalizedImageBox {
  const NormalizedImageBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

class NormalizedImagePoint {
  const NormalizedImagePoint({required this.x, required this.y});

  final double x;
  final double y;
}

class DetectedGarment {
  const DetectedGarment({
    required this.name,
    required this.category,
    required this.detailCategory,
    required this.color,
    required this.fit,
    required this.confidence,
    required this.box,
    this.mask = const [],
    this.preciseColor = '',
    this.colorHex = '',
    this.materialTexture = '',
    this.fitDescription = '',
    this.necklineOrWaist = '',
    this.englishPrompt = '',
    this.generatedImageBase64,
    this.generatedImageMimeType,
    this.generationPrompt,
    this.generationError,
    this.matchedGarmentId,
  });

  final String name;
  final String category;
  final String detailCategory;
  final String color;
  final String fit;
  final double confidence;
  final NormalizedImageBox box;
  final List<NormalizedImagePoint> mask;
  final String preciseColor;
  final String colorHex;
  final String materialTexture;
  final String fitDescription;
  final String necklineOrWaist;
  final String englishPrompt;
  final String? generatedImageBase64;
  final String? generatedImageMimeType;
  final String? generationPrompt;
  final String? generationError;
  final String? matchedGarmentId;

  DetectedGarment copyWith({
    String? name,
    String? category,
    String? detailCategory,
    String? color,
    String? fit,
    double? confidence,
    NormalizedImageBox? box,
    List<NormalizedImagePoint>? mask,
    String? preciseColor,
    String? colorHex,
    String? materialTexture,
    String? fitDescription,
    String? necklineOrWaist,
    String? englishPrompt,
    String? generatedImageBase64,
    String? generatedImageMimeType,
    String? generationPrompt,
    String? generationError,
    String? matchedGarmentId,
    bool clearMatchedGarmentId = false,
  }) =>
      DetectedGarment(
        name: name ?? this.name,
        category: category ?? this.category,
        detailCategory: detailCategory ?? this.detailCategory,
        color: color ?? this.color,
        fit: fit ?? this.fit,
        confidence: confidence ?? this.confidence,
        box: box ?? this.box,
        mask: mask ?? this.mask,
        preciseColor: preciseColor ?? this.preciseColor,
        colorHex: colorHex ?? this.colorHex,
        materialTexture: materialTexture ?? this.materialTexture,
        fitDescription: fitDescription ?? this.fitDescription,
        necklineOrWaist: necklineOrWaist ?? this.necklineOrWaist,
        englishPrompt: englishPrompt ?? this.englishPrompt,
        generatedImageBase64: generatedImageBase64 ?? this.generatedImageBase64,
        generatedImageMimeType:
            generatedImageMimeType ?? this.generatedImageMimeType,
        generationPrompt: generationPrompt ?? this.generationPrompt,
        generationError: generationError ?? this.generationError,
        matchedGarmentId: clearMatchedGarmentId
            ? null
            : matchedGarmentId ?? this.matchedGarmentId,
      );
}

class GeneratedGarmentImage {
  const GeneratedGarmentImage({
    required this.imageBase64,
    required this.mimeType,
    required this.prompt,
  });

  final String imageBase64;
  final String mimeType;
  final String prompt;
}

class OutfitPhotoAnalysis {
  const OutfitPhotoAnalysis({required this.items, required this.summary});

  final List<DetectedGarment> items;
  final String summary;
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
  BackendService({
    FirebaseFunctions? functions,
    http.Client? httpClient,
    String? outfitAnalysisApiUrl,
    String? outfitGenerationApiUrl,
  })  : _functions = functions,
        _httpClient = httpClient ?? http.Client(),
        _outfitAnalysisApiUrl =
            outfitAnalysisApiUrl ?? _defaultOutfitAnalysisApiUrl,
        _outfitGenerationApiUrl = outfitGenerationApiUrl ??
            _deriveGenerationUrl(
                outfitAnalysisApiUrl ?? _defaultOutfitAnalysisApiUrl);

  FirebaseFunctions? _functions;
  final http.Client _httpClient;
  final String _outfitAnalysisApiUrl;
  final String _outfitGenerationApiUrl;

  FirebaseFunctions get _firebaseFunctions =>
      _functions ??= FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  static const String _defaultOutfitAnalysisApiUrl = String.fromEnvironment(
    'CHAKCHAK_AI_API_URL',
    defaultValue:
        'https://chakchak-ai-api.maison-elan-springseed.workers.dev/api/outfit-analysis',
  );

  Future<OutfitPhotoAnalysis> analyzeOutfitPhoto({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    if (imageBytes.isEmpty) {
      throw ArgumentError.value(imageBytes, 'imageBytes', '사진이 비어 있어요.');
    }
    if (imageBytes.lengthInBytes > 8 * 1024 * 1024) {
      throw StateError('사진은 8MB 이하로 선택해주세요.');
    }
    final response = await _httpClient
        .post(
          Uri.parse(_outfitAnalysisApiUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'imageBase64': base64Encode(imageBytes),
            'mimeType': mimeType,
          }),
        )
        .timeout(const Duration(seconds: 90));
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw StateError('착장 사진 분석 응답을 읽지 못했어요. 잠시 후 다시 시도해주세요.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data['error'];
      final nestedError = error is Map
          ? Map<String, dynamic>.from(error)
          : const <String, dynamic>{};
      final message = _stringValue(data['message']) ??
          _stringValue(nestedError['message']) ??
          _stringValue(error) ??
          '착장 사진 분석에 실패했어요.';
      throw StateError(message);
    }
    final analysis = data['analysis'] is Map
        ? Map<String, dynamic>.from(data['analysis'] as Map)
        : data;
    final rawItems = analysis['items'];
    final items = (rawItems is List ? rawItems : const <dynamic>[])
        .whereType<Map>()
        .map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final rawBox = Map<String, dynamic>.from(item['box'] as Map? ?? {});
      final mask = (item['mask'] is List ? item['mask'] as List : const [])
          .whereType<List>()
          .where((point) => point.length >= 2)
          .map((point) => NormalizedImagePoint(
                x: (point[0] as num?)?.toDouble() ?? 0,
                y: (point[1] as num?)?.toDouble() ?? 0,
              ))
          .toList(growable: false);
      double number(String key, [double fallback = 0]) =>
          (rawBox[key] as num?)?.toDouble() ?? fallback;
      return DetectedGarment(
        name: _stringValue(item['name']) ?? '새 옷',
        category: _stringValue(item['category']) ?? '상의',
        detailCategory: _stringValue(item['detailCategory']) ?? '',
        color: _stringValue(item['color']) ?? '기타',
        fit: _stringValue(item['fit']) ?? '기본',
        preciseColor: _stringValue(item['preciseColor']) ?? '',
        colorHex: _stringValue(item['colorHex']) ?? '',
        materialTexture: _stringValue(item['materialTexture']) ?? '',
        fitDescription: _stringValue(item['fitDescription']) ?? '',
        necklineOrWaist: _stringValue(item['necklineOrWaist']) ?? '',
        englishPrompt: _stringValue(item['englishPrompt']) ?? '',
        generatedImageBase64:
            _stringValue((item['generatedImage'] as Map?)?['imageBase64']),
        generatedImageMimeType:
            _stringValue((item['generatedImage'] as Map?)?['mimeType']),
        generationPrompt:
            _stringValue((item['generatedImage'] as Map?)?['prompt']),
        generationError: _stringValue(item['generationError']),
        confidence: (item['confidence'] as num?)?.toDouble() ?? 0,
        matchedGarmentId: _stringValue(item['matchedGarmentId']),
        mask: mask,
        box: NormalizedImageBox(
          x: number('x'),
          y: number('y'),
          width: number('width', 1),
          height: number('height', 1),
        ),
      );
    }).toList(growable: false);
    if (items.isEmpty) {
      throw StateError('사진에서 옷을 찾지 못했어요. 전신이 잘 보이는 사진으로 다시 시도해주세요.');
    }
    return OutfitPhotoAnalysis(
      items: items,
      summary:
          _stringValue(analysis['summary']) ?? '${items.length}개의 옷을 찾았어요.',
    );
  }

  Future<GeneratedGarmentImage> generateGarmentStudioImage({
    required DetectedGarment garment,
  }) async {
    final response = await _httpClient
        .post(
          Uri.parse(_outfitGenerationApiUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'item': {
              'name': garment.name,
              'category': garment.category,
              'detailCategory': garment.detailCategory,
              'color': garment.color,
              'preciseColor': garment.preciseColor,
              'colorHex': garment.colorHex,
              'materialTexture': garment.materialTexture,
              'fit': garment.fit,
              'fitDescription': garment.fitDescription,
              'necklineOrWaist': garment.necklineOrWaist,
              'englishPrompt': garment.englishPrompt,
            },
          }),
        )
        .timeout(const Duration(seconds: 90));
    Map<String, dynamic> data;
    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw StateError('상품컷 생성 응답을 읽지 못했어요.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = data['error'];
      final nested = error is Map
          ? Map<String, dynamic>.from(error)
          : const <String, dynamic>{};
      throw StateError(_stringValue(nested['message']) ??
          _stringValue(data['message']) ??
          _stringValue(error) ??
          '상품컷 생성에 실패했어요.');
    }
    final generated = data['generatedImage'] is Map
        ? Map<String, dynamic>.from(data['generatedImage'] as Map)
        : const <String, dynamic>{};
    final imageBase64 = _stringValue(generated['imageBase64']);
    if (imageBase64 == null) throw StateError('생성된 상품컷이 비어 있어요.');
    return GeneratedGarmentImage(
      imageBase64: imageBase64,
      mimeType: _stringValue(generated['mimeType']) ?? 'image/png',
      prompt: _stringValue(generated['prompt']) ?? garment.englishPrompt,
    );
  }

  static String _deriveGenerationUrl(String analysisUrl) =>
      analysisUrl.replaceFirst(
          RegExp(r'/api/outfit-analysis/?$'), '/api/outfit-generation');

  static String? _stringValue(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> deleteMyData() async {
    await _firebaseFunctions.httpsCallable('deleteMyData').call();
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
    final result =
        await _firebaseFunctions.httpsCallable('recommendOutfit').call({
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
      final result =
          await _firebaseFunctions.httpsCallable('getKmaWeather').call({
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
