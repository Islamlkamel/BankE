import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/account_data_source.dart';

class LogoutUseCase {
  final AccountDataSource dataSource;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  LogoutUseCase(this.dataSource);

  Future<void> call() async {
    await _storage.deleteAll();
    dataSource.reset();
  }
}
