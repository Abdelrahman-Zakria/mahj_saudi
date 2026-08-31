import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:alarm/alarm.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ad_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/rate_service.dart';
import 'features/home/data/repositories/educational_repository_impl.dart';
import 'features/home/presentation/screens/home/home_page.dart';

final sl = GetIt.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //print("Handling a background message: ${message.messageId}");
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    InAppPurchaseStoreKitPlatform.enableStoreKit1();
  }

  // 1. Initialize essential core services first (Fast)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  await Alarm.init();
  final prefs = await SharedPreferences.getInstance();
  
  // 2. Register all services in GetIt immediately
  sl.registerLazySingleton(() => LocalStorageService(prefs));
  
  final notificationService = NotificationService();
  sl.registerLazySingleton(() => notificationService);

  final iapService = IapService();
  sl.registerLazySingleton(() => iapService);

  final adService = AdService();
  adService.navigatorKey = navigatorKey;
  sl.registerLazySingleton(() => adService);
  
  sl.registerLazySingleton(() => EducationalRepositoryImpl(FirebaseFirestore.instance));

  // 3. Start the app immediately to remove the native splash screen
  runApp(const MyApp());
  
  // 4. Initialize heavy/blocking services in the background
  unawaited(notificationService.init());
  unawaited(iapService.init());
  unawaited(adService.init());
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
    
    // Initialize Rate Dialog Timer (shows after 2 minutes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RateService().initRateTimer(navigatorKey.currentContext!);
    });
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
        navigatorKey: navigatorKey,
        title: 'منهجي السعودي',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomePage(),
      ),
    );
  }
}
