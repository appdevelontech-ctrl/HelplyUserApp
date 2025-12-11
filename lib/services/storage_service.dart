import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String onboardingKey = "onboarding_done";

  static Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingKey, true);
    print("True marked");
  }

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(onboardingKey) ?? false;
  }
}
