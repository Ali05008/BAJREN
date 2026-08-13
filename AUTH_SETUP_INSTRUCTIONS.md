# BAJREN — تعليمات ربط شاشات تسجيل الدخول الجديدة

بعد رفع هذا الملف المضغوط (سيوزَّع تلقائيًا عبر GitHub Action)، تحتاج تعديلين
يدويين بسيطين على ملفين موجودين مسبقًا بالمشروع، لأننا ما قدرنا نشوف محتواهما
الحالي فما عدّلناهما مباشرة تجنبًا لأي كسر.

## 1) pubspec.yaml — إضافة الحزم المطلوبة

أضف هذه الأسطر تحت `dependencies:` إذا ما كانت موجودة أصلاً:

```yaml
dependencies:
  google_sign_in: ^6.2.1
  intl: ^0.19.0
  flutter_localizations:
    sdk: flutter
```

وتأكد إن هذا السطر موجود تحت `flutter:` (يفعّل توليد ملفات الترجمة تلقائيًا
أثناء البناء عبر GitHub Actions):

```yaml
flutter:
  generate: true
```

## 2) main.dart — ربط اللغة والشاشة الجديدة

أضف هذا الاستيراد فوق ملف main.dart:

```dart
import 'core/localization/locale_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'features/auth/presentation/login_screen.dart';
```

وحوّل تعريف MaterialApp بحيث يصير بهذا الشكل (لاحظ `locale`,
`localizationsDelegates`, و `supportedLocales` الجديدة):

```dart
ValueListenableBuilder<Locale>(
  valueListenable: LocaleController.instance.locale,
  builder: (context, locale, _) {
    return MaterialApp(
      // ... باقي إعداداتك الحالية (title, theme, إلخ) كما هي
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar'), // اللغة الرسمية الافتراضية
        Locale('en'),
      ],
      home: const LoginScreen(), // أو استبدل الشاشة الحالية بهذي حسب مكان التوجيه
    );
  },
)
```

**ملاحظة:** لو عندك أصلاً `AuthGate` يفحص حالة تسجيل الدخول ويوجّه المستخدم
تلقائيًا (Home أو Login)، خلي `home:` يشاور على الـ AuthGate كالمعتاد، بس
تأكد إن الـ AuthGate يستخدم `LoginScreen()` الجديد من
`features/auth/presentation/login_screen.dart` بدل الشاشة القديمة.

## 3) Google Sign-In — SHA-1 Fingerprint

لازم يكون SHA-1 (ويُفضّل SHA-256 أيضًا) مسجّل في Firebase Console:
Project Settings → Your apps → تطبيق Android → Add fingerprint.
بعد الإضافة، حمّل نسخة جديدة من `google-services.json` واستبدل الموجودة في
`android/app/google-services.json`.

بدون هذي الخطوة، زر "المتابعة عبر جوجل" سيفشل برسالة خطأ من نوع
`ApiException: 10` أو `DEVELOPER_ERROR`.

## 4) الملفات الجديدة المضافة

```
lib/core/auth/auth_service.dart          — كل منطق تسجيل الدخول (إيميل+كلمة مرور، رابط، جوجل)
lib/core/auth/username_resolver.dart     — يحوّل اسم المستخدم إلى إيميل عند الدخول
lib/core/localization/locale_controller.dart — يتحكم بتبديل اللغة عربي/إنجليزي
lib/core/theme/brand_colors.dart         — ألوان الهوية (سماوي/بنفسجي/أسود)
lib/features/auth/presentation/login_screen.dart
lib/features/auth/presentation/register_screen.dart
lib/features/auth/presentation/email_link_sent_screen.dart
lib/features/auth/presentation/widgets/auth_widgets.dart
lib/l10n/app_ar.arb                      — نصوص عربية (اللغة الرسمية)
lib/l10n/app_en.arb                      — نصوص إنجليزية
l10n.yaml                                — إعدادات توليد ملفات الترجمة
```

## 5) نقطة تحتاج انتباهك لاحقًا

في `lib/core/auth/username_resolver.dart` افترضنا إن بيانات المستخدمين
محفوظة في Realtime Database بالشكل:
```
/users/{uid}/username
/users/{uid}/email
```
لو الشكل الفعلي مختلف عندك، قول لي وأعدّل الاستعلام ليطابق قاعدة بياناتك
الحقيقية.
