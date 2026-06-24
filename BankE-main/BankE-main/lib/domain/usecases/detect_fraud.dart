import '../repositories/account_repository.dart';
import '../services/location_service.dart';
import '../../core/utils/geo_utils.dart';

class FraudException implements Exception {
  final String message;
  FraudException(this.message);
  @override
  String toString() => message;
}

class DetectFraudUseCase {
  final AccountRepository repository;
  final LocationService locationService;
  
  DetectFraudUseCase(this.repository, this.locationService);
  
  Future<void> execute({
    required String accountId,
    required double amount,
  }) async {
    // 1. Large transaction detection
    if (amount >= 10000) {
      throw FraudException('Fraud Alert: Unusually large transaction detected (\$${amount.toStringAsFixed(2)}).');
    }
    
    // 2. Rapid transactions detection
    final transactions = await repository.getTransactions(accountId);
    final now = DateTime.now();
    
    final recentTransactions = transactions.where((tx) => 
      !tx.isCredit && now.difference(tx.date).inMinutes < 5
    ).toList();
    
    if (recentTransactions.length >= 3) {
      throw FraudException('Fraud Alert: Rapid transactions detected (${recentTransactions.length} inside last 5 minutes).');
    }
    
    // 3. Location anomaly detection (Geofencing)
    final currentLoc = await locationService.getCurrentLocation();
    final trustedZones = locationService.getTrustedZones();

    bool isTrusted = false;
    for (var zone in trustedZones) {
      double dist = GeoUtils.calculateDistance(
        currentLoc['lat']!, currentLoc['lng']!, 
        zone['lat']!, zone['lng']!
      );
      if (dist <= 50.0) { // 50km radius
        isTrusted = true;
        break;
      }
    }

    if (!isTrusted) {
      throw FraudException('Fraud Alert: Location anomaly detected. You are outside trusted geofenced zones.');
    }
  }
}
