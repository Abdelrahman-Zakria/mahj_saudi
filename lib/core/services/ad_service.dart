import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:developer' as dev;

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoading = false;
  Timer? _periodicAdTimer;
  bool _isAdShowing = false;

  // IDs for Android
  static const String androidBannerId = 'ca-app-pub-5716551354866412/3117135380';
  static const String androidInterstitialId = 'ca-app-pub-5716551354866412/9376401917';
  static const String androidAppOpenId = 'ca-app-pub-5716551354866412/3392467552';

  // IDs for iOS
  static const String iosBannerId = 'ca-app-pub-5716551354866412/2859095021';
  static const String iosInterstitialId = 'ca-app-pub-5716551354866412/5803722482';
  static const String iosAppOpenId = 'ca-app-pub-5716551354866412/8063320241';

  String get bannerAdUnitId => Platform.isAndroid ? androidBannerId : iosBannerId;
  String get interstitialAdUnitId => Platform.isAndroid ? androidInterstitialId : iosInterstitialId;
  String get appOpenAdUnitId => Platform.isAndroid ? androidAppOpenId : iosAppOpenId;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadAppOpenAd(showAfterLoad: true);
    loadInterstitialAd();
    startPeriodicAds();
  }

  void startPeriodicAds() {
    _periodicAdTimer?.cancel();
    _periodicAdTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (!_isAdShowing) {
        dev.log("Triggering 3-minute periodic interstitial ad");
        showInterstitialAd(onAdDismissed: () {});
      }
    });
  }

  void dispose() {
    _periodicAdTimer?.cancel();
  }

  // --- App Open Ad ---
  void loadAppOpenAd({bool showAfterLoad = false}) {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          dev.log('AppOpenAd loaded');
          _appOpenAd = ad;
          if (showAfterLoad) {
            showAppOpenAdIfAvailable();
          }
        },
        onAdFailedToLoad: (error) {
          dev.log('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    if (_isAdShowing) return;
    if (_appOpenAd == null) {
      dev.log('AppOpenAd not ready, loading new one...');
      loadAppOpenAd();
      return;
    }
    dev.log('Attempting to show AppOpenAd...');
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAdShowing = true;
        dev.log('AppOpenAd showing on screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isAdShowing = false;
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isAdShowing = false;
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }

  // --- Banner Ad ---
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => dev.log('BannerAd loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          dev.log('BannerAd failed to load: $error');
        },
      ),
    );
  }

  // --- Interstitial Ad ---
  void loadInterstitialAd() {
    if (_isInterstitialAdLoading) return;
    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          dev.log('InterstitialAd loaded');
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          dev.log('InterstitialAd failed to load: $error');
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd({required Function onAdDismissed}) {
    if (_isAdShowing) {
      onAdDismissed();
      return;
    }

    if (_interstitialAd == null) {
      dev.log('InterstitialAd not ready, proceeding to content.');
      onAdDismissed();
      loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAdShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAdShowing = false;
        _interstitialAd = null;
        onAdDismissed();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isAdShowing = false;
        _interstitialAd = null;
        onAdDismissed();
        loadInterstitialAd();
      },
    );
    _interstitialAd!.show();
  }
}
