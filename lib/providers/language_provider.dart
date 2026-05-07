import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _languagePreferenceKey = 'app_language_code';

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>((ref) {
  return AppLanguageController()..load();
});

class AppLanguageController extends StateNotifier<AppLanguage> {
  AppLanguageController() : super(AppLanguage.english);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = AppLanguage.fromCode(prefs.getString(_languagePreferenceKey));
    } on PlatformException catch (error, stackTrace) {
      _logLanguagePreferenceError('load', error, stackTrace);
      state = AppLanguage.english;
    } catch (error, stackTrace) {
      _logLanguagePreferenceError('load', error, stackTrace);
      state = AppLanguage.english;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languagePreferenceKey, language.code);
    } on PlatformException catch (error, stackTrace) {
      _logLanguagePreferenceError('save', error, stackTrace);
    } catch (error, stackTrace) {
      _logLanguagePreferenceError('save', error, stackTrace);
    }
  }
}

void _logLanguagePreferenceError(
  String operation,
  Object error,
  StackTrace stackTrace,
) {
  if (kDebugMode) {
    debugPrint('Language preference $operation failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
