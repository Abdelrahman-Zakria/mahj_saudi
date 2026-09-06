import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:alarm/alarm.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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

  if (message.notification != null) {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('notifications_history');
    List history = [];
    if (data != null) {
      try {
        history = jsonDecode(data);
      } catch (_) {}
    }

    // Check if already exists
    final bool alreadyExists = history.any(
      (e) =>
          e['title'] == message.notification!.title &&
          e['body'] == message.notification!.body,
    );

    if (!alreadyExists) {
      history.insert(0, {
        'title': message.notification!.title,
        'body': message.notification!.body,
        'image': message.notification!.android?.imageUrl ?? message.notification!.apple?.imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (history.length > 50) history.removeLast();
      await prefs.setString('notifications_history', jsonEncode(history));
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS) {
    InAppPurchaseStoreKitPlatform.enableStoreKit1();
  }

  // 1. Initialize essential core services first (Fast)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

  sl.registerLazySingleton(
    () => EducationalRepositoryImpl(FirebaseFirestore.instance),
  );

  // 3. Start the app immediately to remove the native splash screen
  runApp(const MyApp());

  // 4. Initialize heavy/blocking services in a specific sequence to avoid dialog conflicts
  _initializeBackgroundServices(notificationService, iapService, adService);
}

Future<void> _initializeBackgroundServices(
  NotificationService notificationService,
  IapService iapService,
  AdService adService,
) async {
  // Wait a small moment for the UI to be fully rendered
  await Future.delayed(const Duration(milliseconds: 800));

  // 1. Initialize IAP so the ad-free status is known before loading ads
  await iapService.init();

  // 2. Initialize Ads early so the first App Open ad appears at startup
  await adService.init();

  // 3. Initialize notifications after ads so permission dialogs do not delay them
  await Future.delayed(const Duration(milliseconds: 1200));
  await notificationService.init();
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
    RateService().dispose();
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
        builder: (context, child) => _AdSupportedApp(child: child),
        home: const HomePage(),
      ),
    );
  }
}

class _AdSupportedApp extends StatelessWidget {
  final Widget? child;

  const _AdSupportedApp({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child ?? const SizedBox.shrink()),
        const _GlobalBannerAd(),
      ],
    );
  }
}

class _GlobalBannerAd extends StatefulWidget {
  const _GlobalBannerAd();

  @override
  State<_GlobalBannerAd> createState() => _GlobalBannerAdState();
}

class _GlobalBannerAdState extends State<_GlobalBannerAd> {
  BannerAd? _bannerAd;
  StreamSubscription<bool>? _adFreeSubscription;
  Timer? _bannerRetryTimer;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _adFreeSubscription = IapService().adFreeStatusStream.listen((isAdFree) {
      if (!mounted) return;
      if (isAdFree) {
        _bannerAd?.dispose();
        setState(() {
          _bannerAd = null;
          _isLoaded = false;
        });
      } else if (_bannerAd == null) {
        _loadBannerAd();
      }
    });
  }

  void _loadBannerAd() {
    _bannerRetryTimer?.cancel();

    if (!AdService().isMobileAdsInitialized) {
      _scheduleBannerRetry(const Duration(seconds: 2));
      return;
    }

    final bannerAd = AdService().createBannerAd(
      onLoaded: () {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      onFailedToLoad: (_) {
        if (mounted) {
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
          _scheduleBannerRetry(const Duration(seconds: 8));
        }
      },
    );
    if (bannerAd == null) {
      _scheduleBannerRetry(const Duration(seconds: 2));
      return;
    }

    setState(() => _isLoaded = false);
    _bannerAd = bannerAd;
    bannerAd.load();
  }

  void _scheduleBannerRetry(Duration delay) {
    _bannerRetryTimer?.cancel();
    _bannerRetryTimer = Timer(delay, () {
      if (mounted && _bannerAd == null && !IapService().isAdFree) {
        _loadBannerAd();
      }
    });
  }

  @override
  void dispose() {
    _adFreeSubscription?.cancel();
    _bannerRetryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    if (IapService().isAdFree || bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: bannerAd.size.height.toDouble(),
        alignment: Alignment.center,
        color: Colors.white,
        child: _isLoaded
            ? SizedBox(
                width: bannerAd.size.width.toDouble(),
                height: bannerAd.size.height.toDouble(),
                child: AdWidget(ad: bannerAd),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
