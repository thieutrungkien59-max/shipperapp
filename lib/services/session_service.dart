import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();

  static const _accessTokenKey = 'accessToken';
  static const _accountIdKey = 'maTk';
  static const _driverIdKey = 'maSp';
  static const _userNameKey = 'currentUserName';
  static const _userRoleKey = 'currentUserRole';
  static const _secureStorage = FlutterSecureStorage();

  static Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _accessTokenKey);
  }

  static Future<void> saveSession({
    required String accountId,
    required String driverId,
    String? accessToken,
    String? userName,
    String? userRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountIdKey, accountId);
    await prefs.setString(_driverIdKey, driverId);

    if (accessToken != null && accessToken.isNotEmpty) {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
    }

    if (userName != null && userName.isNotEmpty) {
      await prefs.setString(_userNameKey, userName);
    }
    if (userRole != null && userRole.isNotEmpty) {
      await prefs.setString(_userRoleKey, userRole);
    }
  }

  static Future<bool> hasSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accountId = prefs.getString(_accountIdKey);
    final driverId = prefs.getString(_driverIdKey);
    return accountId != null &&
        accountId.isNotEmpty &&
        driverId != null &&
        driverId.isNotEmpty;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _accessTokenKey);
    await Future.wait([
      prefs.remove(_accountIdKey),
      prefs.remove(_driverIdKey),
      prefs.remove(_userNameKey),
      prefs.remove(_userRoleKey),
    ]);
  }
}
