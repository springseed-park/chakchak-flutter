import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'backend_service.dart';

class LocatedWeather {
  const LocatedWeather({required this.locationLabel, required this.weather});

  final String locationLabel;
  final WeatherSnapshot weather;
}

class LocatedRegion {
  const LocatedRegion({
    required this.region,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
  });

  final String region;
  final String locationLabel;
  final double latitude;
  final double longitude;
}

class LocationWeatherService {
  LocationWeatherService({BackendService? backend}) : _backend = backend;

  BackendService? _backend;
  Geocoding? _geocoding;

  BackendService get _weatherBackend => _backend ??= BackendService();
  Geocoding get _reverseGeocoder => _geocoding ??= Geocoding();

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException('위치 권한이 필요합니다.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  String _shortRegion(String value) {
    final compact = value
        .replaceAll('특별자치도', '')
        .replaceAll('특별자치시', '')
        .replaceAll('특별시', '')
        .replaceAll('광역시', '')
        .replaceAll(RegExp(r'도$'), '')
        .trim();
    const aliases = {
      '서울': '서울',
      '인천': '인천',
      '대전': '대전',
      '대구': '대구',
      '부산': '부산',
      '광주': '광주',
      '울산': '울산',
      '강원': '강원',
      '경기': '경기',
      '충청남': '충남',
      '충청북': '충북',
      '전라남': '전남',
      '전라북': '전북',
      '세종': '세종',
      '경상남': '경남',
      '경상북': '경북',
      '제주': '제주',
    };
    return aliases[compact] ?? compact;
  }

  Future<LocatedRegion> locateCurrentRegion() async {
    final position = await _currentPosition();
    try {
      final uri = Uri.https(
        'api.bigdatacloud.net',
        '/data/reverse-geocode-client',
        {
          'latitude': '${position.latitude}',
          'longitude': '${position.longitude}',
          'localityLanguage': 'ko',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw StateError('주소 조회 실패 (${response.statusCode})');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final administrative =
          ((data['localityInfo'] as Map<String, dynamic>?)?['administrative']
                      as List<dynamic>? ??
                  const [])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      String adminName(int level) =>
          administrative
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (item) => item?['adminLevel'] == level,
                orElse: () => null,
              )?['name']
              ?.toString()
              .trim() ??
          '';
      final subdivision = data['principalSubdivision']?.toString().trim() ?? '';
      final city = data['city']?.toString().trim() ?? subdivision;
      final district = adminName(6);
      final locality = (data['locality']?.toString().trim().isNotEmpty == true
          ? data['locality'].toString().trim()
          : adminName(8));
      final region = _shortRegion(subdivision.isNotEmpty ? subdivision : city);
      final labelParts = <String>[
        _shortRegion(city),
        district,
        locality,
      ].where((item) => item.isNotEmpty).toSet().toList(growable: false);
      return LocatedRegion(
        region: region,
        locationLabel: labelParts.isEmpty ? '현재 위치' : labelParts.join(' '),
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      var label = '현재 위치';
      var region = '';
      try {
        final placemarks = await _reverseGeocoder.placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          region = _shortRegion(place.administrativeArea?.trim() ?? '');
          final parts = [
            region,
            place.subAdministrativeArea?.trim() ?? '',
            place.subLocality?.trim() ?? '',
          ].where((item) => item.isNotEmpty).toSet();
          if (parts.isNotEmpty) label = parts.join(' ');
        }
      } catch (_) {
        // 주소 서비스가 실패해도 위치 권한 자체는 정상 처리합니다.
      }
      return LocatedRegion(
        region: region,
        locationLabel: label,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  }

  Future<LocatedWeather> loadCurrentWeather() async {
    final located = await locateCurrentRegion();
    return loadWeatherForLocatedRegion(located);
  }

  Future<LocatedWeather> loadWeatherForLocatedRegion(
    LocatedRegion located,
  ) async {
    final weather = await _weatherBackend.getWeather(
      latitude: located.latitude,
      longitude: located.longitude,
    );
    return LocatedWeather(
        locationLabel: located.locationLabel, weather: weather);
  }

  static const Map<String, (double latitude, double longitude)>
      _regionCoordinates = {
    '서울': (37.5665, 126.9780),
    '인천': (37.4563, 126.7052),
    '대전': (36.3504, 127.3845),
    '대구': (35.8714, 128.6014),
    '부산': (35.1796, 129.0756),
    '광주': (35.1595, 126.8526),
    '울산': (35.5384, 129.3114),
    '강원': (37.8854, 127.7298),
    '경기': (37.2636, 127.0286),
    '충남': (36.6588, 126.6728),
    '충북': (36.6357, 127.4917),
    '전남': (34.8161, 126.4629),
    '전북': (35.8203, 127.1088),
    '세종': (36.4800, 127.2890),
    '경남': (35.2383, 128.6924),
    '경북': (36.5760, 128.5056),
    '제주': (33.4996, 126.5312),
  };

  Future<LocatedWeather> loadWeatherForRegion(String region) async {
    final coordinates = _regionCoordinates[region];
    if (coordinates == null) {
      throw ArgumentError.value(region, 'region', '지원하지 않는 지역입니다.');
    }
    final weather = await _weatherBackend.getWeather(
      latitude: coordinates.$1,
      longitude: coordinates.$2,
    );
    return LocatedWeather(locationLabel: region, weather: weather);
  }
}
