import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/firebase_options.dart';
import 'package:gymsaas/l10n/app_localizations.dart';
import 'package:gymsaas/navigation/router.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/language_provider.dart';
import 'package:gymsaas/widgets/apex_text.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: ApexApp()));
}

class ApexApp extends ConsumerWidget {
  const ApexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final authUser = authAsync.valueOrNull ?? FirebaseAuth.instance.currentUser;
    final language = ref.watch(appLanguageProvider);

    if (authAsync.isLoading && authUser == null) {
      return _LocalizedMaterialApp(
        language: language,
        home: const _AuthLoadingScreen(),
      );
    }

    if (authUser != null) {
      final profileAsync = ref.watch(currentUserProfileProvider);
      return profileAsync.when(
        loading: () => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: apexTheme,
          locale: language.locale,
          supportedLocales: AppLanguage.values.map((item) => item.locale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const _AuthLoadingScreen(),
        ),
        error: (error, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: apexTheme,
          locale: language.locale,
          supportedLocales: AppLanguage.values.map((item) => item.locale),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: _AuthProfileErrorScreen(
            title: 'Profile Load Failed',
            message:
                'We could not load your user profile from Firestore.\n$error',
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: apexTheme,
              locale: language.locale,
              supportedLocales: AppLanguage.values.map((item) => item.locale),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              home: const _MissingProfileScreen(),
            );
          }

          final router = ref.watch(routerProvider);
          return _LocalizedMaterialApp.router(
            language: language,
            title: 'APEX Gym Management',
            routerConfig: router,
          );
        },
      );
    }

    final router = ref.watch(routerProvider);
    return _LocalizedMaterialApp.router(
      language: language,
      title: 'APEX Gym Management',
      routerConfig: router,
    );
  }
}

class _LocalizedMaterialApp extends StatelessWidget {
  const _LocalizedMaterialApp({
    required this.language,
    required this.home,
  })  : routerConfig = null,
        title = 'APEX Gym Management';

  const _LocalizedMaterialApp.router({
    required this.language,
    required this.title,
    required this.routerConfig,
  }) : home = null;

  final AppLanguage language;
  final String title;
  final Widget? home;
  final RouterConfig<Object>? routerConfig;

  static const _delegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  @override
  Widget build(BuildContext context) {
    if (routerConfig != null) {
      return MaterialApp.router(
        title: title,
        debugShowCheckedModeBanner: false,
        theme: apexTheme,
        locale: language.locale,
        supportedLocales: AppLanguage.values.map((item) => item.locale),
        localizationsDelegates: _delegates,
        routerConfig: routerConfig,
      );
    }

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: apexTheme,
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((item) => item.locale),
      localizationsDelegates: _delegates,
      home: home,
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: CircularProgressIndicator(color: gold),
      ),
    );
  }
}

class _AuthProfileErrorScreen extends ConsumerWidget {
  final String title;
  final String message;

  const _AuthProfileErrorScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderDark),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: redAlert, size: 36),
              const SizedBox(height: 16),
              ApexText(
                title,
                fontSize: 18,
                color: const Color(0xFFE8E8E8),
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ApexText(
                message,
                fontSize: 12,
                color: const Color(0xFF888888),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.read(authControllerProvider).signOut(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('SIGN OUT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingProfileScreen extends ConsumerWidget {
  const _MissingProfileScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAuthUserProvider);
    final uid = user?.uid ?? 'Unknown';
    final email = user?.email ?? 'No email';

    return _AuthProfileErrorScreen(
      title: 'User Profile Not Found',
      message:
          'You are signed in as $email, but no users/$uid profile document exists.\n'
          'Create the Firestore profile manually, then sign in again.',
    );
  }
}
