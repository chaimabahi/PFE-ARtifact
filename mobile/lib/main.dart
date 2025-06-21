import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/firestore_service.dart';
import 'core/services/image_upload_service.dart';
import 'firebase_options.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/navigation/screens/main_navigation.dart';
import 'shared/l10n/app_localizations.dart';
import 'shared/theme/app_theme.dart';

// Cloudinary configuration
const String CLOUDINARY_CLOUD_NAME = 'du4beik3f'; // Replace with your cloud name
const String CLOUDINARY_UPLOAD_PRESET = 'chaimabahi'; // Replace with your upload preset

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51RBcHlPbbTAwLSrs2kW4eWA2EwQGTJyGaUDLmpjxzeaZn2ypVafqlPin7j07wTJZHavUGnxJkee5CKjhEGoG03N100RWjc5NXY';
  // Initialize Firebase safely
  await _initializeFirebase();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(MyApp(prefs: prefs));
}

Future<void> _initializeFirebase() async {
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // If already initialized, use the existing app
    }
  } catch (e) {
    print('Firebase initialization error: $e');
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Add Firestore service provider
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        // Add ImageUploadService provider with Cloudinary configuration
        Provider<ImageUploadService>(
          create: (_) => ImageUploadService(
            cloudName: "du4beik3f",
            uploadPreset: "chaimabahi",
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => LocaleProvider(prefs),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            title: 'ARtifact',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('fr', ''), // French
              Locale('ar', ''), // Arabic
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
