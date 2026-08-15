import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:alarm/alarm.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';
import 'features/home/data/repositories/educational_repository_impl.dart';
import 'features/home/presentation/screens/home/home_page.dart';

final sl = GetIt.instance;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Alarm.init();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  
  // Register Services
  sl.registerLazySingleton(() => LocalStorageService(prefs));
  final notificationService = NotificationService();
  await notificationService.init();
  sl.registerLazySingleton(() => notificationService);

  final adService = AdService();
  await adService.init();
  sl.registerLazySingleton(() => adService);
  
  // Register Repository
  sl.registerLazySingleton(() => EducationalRepositoryImpl(FirebaseFirestore.instance));

  runApp(const MyApp());
  
  // Remove splash after initialization
  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<AdService>().showAppOpenAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<EducationalRepositoryImpl>(
          create: (context) => sl<EducationalRepositoryImpl>(),
        ),
      ],
      child: MaterialApp(
        title: 'منهجي السعودي',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomePage(),
      ),
    );
  }
}
