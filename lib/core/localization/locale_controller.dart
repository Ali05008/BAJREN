import 'package:flutter/material.dart';

/// Global, lightweight locale controller.
/// Arabic ('ar') is BAJREN's official/default language; English ('en') is
/// offered as an additional option via the language toggle in the app bar.
///
/// Wire this into MaterialApp like:
///   ValueListenableBuilder<Locale>(
///     valueListenable: LocaleController.instance.locale,
///     builder: (context, locale, _) => MaterialApp(
///       locale: locale,
///       ...
///     ),
///   )
class LocaleController {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const Locale defaultLocale = Locale('ar');

  final ValueNotifier<Locale> locale = ValueNotifier<Locale>(defaultLocale);

  void toggle() {
    locale.value =
        locale.value.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
  }

  void setLocale(Locale newLocale) {
    locale.value = newLocale;
  }
}
