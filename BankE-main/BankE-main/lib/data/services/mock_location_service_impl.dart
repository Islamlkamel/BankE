import '../../domain/services/location_service.dart';

class MockLocationServiceImpl implements LocationService {
  // Default to New York (Trusted Zone)
  Map<String, double> _currentLocation = {'lat': 40.7128, 'lng': -74.0060};

  @override
  Future<Map<String, double>> getCurrentLocation() async {
    // Artificial delay measuring GPS ping
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentLocation;
  }

  @override
  List<Map<String, double>> getTrustedZones() {
    return [
      {'lat': 40.7128, 'lng': -74.0060}, // New York
      {'lat': 34.0522, 'lng': -118.2437}, // Los Angeles
    ];
  }

  @override
  Future<void> setMockLocation(double lat, double lng) async {
    _currentLocation = {'lat': lat, 'lng': lng};
  }
}
