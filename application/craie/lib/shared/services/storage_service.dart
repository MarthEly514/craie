import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small key/value storage that survives app restarts.
class StorageService extends GetxService {
  static const _onboardingKey = 'onboarding_done';
  static const _refreshTokenKey = 'refresh_token';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingDone() => _prefs.setBool(_onboardingKey, true);

  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  Future<void> saveRefreshToken(String? token) => token == null
      ? _prefs.remove(_refreshTokenKey)
      : _prefs.setString(_refreshTokenKey, token);
}
