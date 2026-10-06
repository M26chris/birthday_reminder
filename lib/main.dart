import 'package:birthday_reminder/auth_wrapper.dart';
import 'package:birthday_reminder/firebase_options.dart';
import 'package:birthday_reminder/js_bindings/js_ignore_bindings.dart'
    if (dart.library.html) 'package:birthday_reminder/js_bindings/js_bindings.dart';
import 'package:birthday_reminder/helpers/birthday_notification.dart';
import 'package:birthday_reminder/theme.dart';
import 'package:birthday_reminder/util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

void main() async {
  // Catch all errors thrown inside Flutter framework
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── Crashlytics setup ──────────────────────────────────────────────
  // Disable in debug mode so crashes are shown in console, not silenced
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);

  // Catch all Flutter framework errors (widget build failures, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug: print to console as normal
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In release: send to Crashlytics
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // Catch all errors thrown OUTSIDE Flutter framework
  // (async errors, Dart isolate errors, etc.)
  PlatformDispatcher.instance.onError = (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };
  // ──────────────────────────────────────────────────────────────────

  // Initialize local notifications (fixes timezone + exact scheduling)
  await BirthdayNotificationManager().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    if (kIsWeb) {
      appFinishedLoading();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // English only
    const locale = Locale('en');

    if (kIsWeb) {
      setWebLocale(locale);
    }

    return MaterialApp(
      title: 'Remindra',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: RemindraTheme.lightTheme(),
      darkTheme: RemindraTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) => const AppAuthWrapper(),
      ),
    );
  }
}
