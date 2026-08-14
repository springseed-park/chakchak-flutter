import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'backend_service.dart';

class LocatedWeather {
  const LocatedWeather({required this.locationLabel, required this.weather});

  final String locationLabel;
  final WeatherSnapshot weather;
}

class LocationWeatherService {
  LocationWeatherService({BackendService? backend}) : _backend = backend;

  BackendService? _backend;
  Geocoding? _geocoding;

  BackendService get _weatherBackend => _backend ??= BackendService();
  Geocoding get _reverseGeocoder => _geocoding ??= Geocoding();

  Future<LocatedWeather> loadCurrentWeather() async {
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
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
    final weather = await _weatherBackend.getWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    var label = '현재 위치';
    try {
      final placemarks = await _reverseGeocoder.placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality?.trim().isNotEmpty == true
            ? place.locality!.trim()
            : place.administrativeArea?.trim() ?? '';
        final district = place.subLocality?.trim().isNotEmpty == true
            ? place.subLocality!.trim()
            : place.subAdministrativeArea?.trim() ?? '';
        final parts = [city, district].where((value) => value.isNotEmpty);
        if (parts.isNotEmpty) label = parts.join(' ');
      }
    } catch (_) {
      // 역지오코딩 실패 시에도 기상청 좌표 예보는 정상 표시합니다.
    }
    return LocatedWeather(locationLabel: label, weather: weather);
  }
}
