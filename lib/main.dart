import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_environment.dart';
import 'auth/go_router_auth_refresh.dart';
import 'app_router.dart';
import 'data/placeholder/in_memory_store.dart';
import 'data/providers.dart';
import 'firebase_options.dart';
import 'services/ads_service.dart';
import 'services/app_logger.dart';
import 'services/app_profiler.dart';
import 'services/background_training_service.dart';
import 'services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppProfiler.trace('app_bootstrap', () async {
      await AdsService.initialize();
      await LocalNotificationService.instance.initialize();
      await LocalNotificationService.instance.requestPermission();
      await BackgroundTrainingService.initialize();
    });
  } catch (error, stackTrace) {
    AppLogger.warning(
      'Optional mobile services unavailable',
      error: error,
      stackTrace: stackTrace,
    );
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (error) {
    AppEnvironment.useLocalData();
    AppLogger.warning('Firebase unavailable on this platform', error: error);
  }
  goRouterAuthRefresh.listenToAuth(activeAuthRepository());
  InMemoryStore.instance.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color _bg = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    final baseDark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bg,
    );

    return MaterialApp.router(
      title: 'Wicket Wars',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: baseDark.copyWith(
        textTheme: GoogleFonts.montserratTextTheme(baseDark.textTheme),
      ),
    );
  }
}
