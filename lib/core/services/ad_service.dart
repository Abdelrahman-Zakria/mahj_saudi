import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'iap_service.dart';
import 'dart:developer' as dev;

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  Timer? _appOpenAdRetryTimer;
  Timer? _interstitialAdRetryTimer;
  bool _isAppOpenAdLoading = false;
  bool _isInterstitialAdLoading = false;
  bool _isMobileAdsInitialized = false;
  bool _showAppOpenAfterLoad = false;
  bool _showInterstitialAfterLoad = false;
  Timer? _appOpenAdTimer;
  Timer? _interstitialAdTimer;
  bool _isAdShowing = false;
  GlobalKey<NavigatorState>? navigatorKey;

  static const Duration appOpenAdInterval = Duration(seconds: 40);
  static const Duration interstitialAdInterval = Duration(seconds: 90);

  static const String androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String androidAppOpenId =
      'ca-app-pub-3940256099942544/9257395921';

  static const String iosBannerId = 'ca-app-pub-6520884181780729/3297080273';
  static const String iosInterstitialId =
      'ca-app-pub-6520884181780729/7530120125';
  static const String iosAppOpenId = 'ca-app-pub-6520884181780729/6093644324';

  String get bannerAdUnitId =>
      Platform.isAndroid ? androidBannerId : iosBannerId;

  String get interstitialAdUnitId {
    return Platform.isAndroid ? androidInterstitialId : iosInterstitialId;
  }

  String get appOpenAdUnitId {
    return Platform.isAndroid ? androidAppOpenId : iosAppOpenId;
  }

  bool get isMobileAdsInitialized => _isMobileAdsInitialized;

  Future<void> init() async {
    if (IapService().isAdFree) {
      dev.log('User is ad-free, skipping MobileAds init');
      return;
    }

    // Listen for ad-free status changes
    IapService().adFreeStatusStream.listen((isAdFree) {
      if (isAdFree) {
        _clearAds();
        dev.log('Ad-free enabled: Cleared all ads and timers');
      }
    });

    await MobileAds.instance.initialize();
    _isMobileAdsInitialized = true;
    loadAppOpenAd(showAfterLoad: true);
    loadInterstitialAd();
    startPeriodicAds();
  }

  void startPeriodicAds() {
    if (IapService().isAdFree) return;
    _appOpenAdTimer?.cancel();
    _interstitialAdTimer?.cancel();

    _appOpenAdTimer = Timer.periodic(appOpenAdInterval, (timer) {
      if (!_isAdShowing && !IapService().isAdFree) {
        dev.log("Triggering 40-second periodic App Open ad");
        showAppOpenAdIfAvailable(loadAndShowWhenReady: true);
      } else if (IapService().isAdFree) {
        timer.cancel();
      }
    });

    _interstitialAdTimer = Timer.periodic(interstitialAdInterval, (timer) {
      if (!_isAdShowing && !IapService().isAdFree) {
        dev.log("Triggering 90-second periodic Interstitial ad");
        showInterstitialAd(onAdDismissed: () {}, loadAndShowWhenReady: true);
      } else if (IapService().isAdFree) {
        timer.cancel();
      }
    });
  }

  void dispose() {
    _clearAds();
  }

  void _clearAds() {
    _appOpenAdTimer?.cancel();
    _interstitialAdTimer?.cancel();
    _appOpenAdRetryTimer?.cancel();
    _interstitialAdRetryTimer?.cancel();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
    _appOpenAd = null;
    _interstitialAd = null;
    _isAppOpenAdLoading = false;
    _isInterstitialAdLoading = false;
    _showAppOpenAfterLoad = false;
    _showInterstitialAfterLoad = false;
  }

  bool get _canRequestAds =>
      _isMobileAdsInitialized && !IapService().isAdFree && !_isAdShowing;

  void _retryAppOpenLoad() {
    _appOpenAdRetryTimer?.cancel();
    _appOpenAdRetryTimer = Timer(const Duration(seconds: 8), loadAppOpenAd);
  }

  void _retryInterstitialLoad() {
    _interstitialAdRetryTimer?.cancel();
    _interstitialAdRetryTimer = Timer(
      const Duration(seconds: 8),
      loadInterstitialAd,
    );
  }

  void _showErrorDialog(String type, dynamic error) {
    // Disabled for production to prevent technical popups for users
    dev.log('Ad Error ($type): ${error.toString()}');
  }

  // --- App Open Ad ---
  void loadAppOpenAd({bool showAfterLoad = false}) {
    if (IapService().isAdFree || !_isMobileAdsInitialized) return;
    if (showAfterLoad) {
      _showAppOpenAfterLoad = true;
    }
    if (_appOpenAd != null) {
      if (showAfterLoad) {
        showAppOpenAdIfAvailable();
      }
      return;
    }
    if (_isAppOpenAdLoading) return;

    _isAppOpenAdLoading = true;
    _appOpenAdRetryTimer?.cancel();
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          dev.log('AppOpenAd loaded');
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
          if (_showAppOpenAfterLoad) {
            _showAppOpenAfterLoad = false;
            showAppOpenAdIfAvailable();
          }
        },
        onAdFailedToLoad: (error) {
          dev.log('AppOpenAd failed to load: $error');
          _isAppOpenAdLoading = false;
          _appOpenAd = null;
          _showErrorDialog('App Open Load', error);
          _retryAppOpenLoad();
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable({bool loadAndShowWhenReady = false}) {
    if (!_canRequestAds) return;
    if (_appOpenAd == null) {
      dev.log('AppOpenAd not ready, loading new one...');
      loadAppOpenAd(showAfterLoad: loadAndShowWhenReady);
      return;
    }

    dev.log('Attempting to show AppOpenAd...');
    final ad = _appOpenAd!;
    _appOpenAd = null;
    _isAdShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        dev.log('AppOpenAd showing on screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAdShowing = false;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isAdShowing = false;
        loadAppOpenAd();
        _showErrorDialog('App Open Show', error);
      },
    );
    ad.show();
  }

  // --- Banner Ad ---
  BannerAd? createBannerAd({
    VoidCallback? onLoaded,
    void Function(LoadAdError error)? onFailedToLoad,
  }) {
    if (IapService().isAdFree || !_isMobileAdsInitialized) return null;
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          dev.log('BannerAd loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          dev.log('BannerAd failed to load: $error');
          onFailedToLoad?.call(error);
          _showErrorDialog('Banner Load', error);
        },
      ),
    );
  }

  // --- Interstitial Ad ---
  void loadInterstitialAd({bool showAfterLoad = false}) {
    if (IapService().isAdFree || !_isMobileAdsInitialized) return;
    if (showAfterLoad) {
      _showInterstitialAfterLoad = true;
    }
    if (_interstitialAd != null) {
      if (showAfterLoad) {
        showInterstitialAd(onAdDismissed: () {});
      }
      return;
    }
    if (_isInterstitialAdLoading) return;

    _isInterstitialAdLoading = true;
    _interstitialAdRetryTimer?.cancel();
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          dev.log('InterstitialAd loaded');
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          if (_showInterstitialAfterLoad) {
            _showInterstitialAfterLoad = false;
            showInterstitialAd(onAdDismissed: () {});
          }
        },
        onAdFailedToLoad: (error) {
          dev.log('InterstitialAd failed to load: $error');
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
          _showErrorDialog('Interstitial Load', error);
          _retryInterstitialLoad();
        },
      ),
    );
  }

  void showInterstitialAd({
    required Function onAdDismissed,
    bool loadAndShowWhenReady = false,
  }) {
    if (!_canRequestAds) {
      onAdDismissed();
      return;
    }

    if (_interstitialAd == null) {
      dev.log('InterstitialAd not ready, proceeding to content.');
      onAdDismissed();
      loadInterstitialAd(showAfterLoad: loadAndShowWhenReady);
      return;
    }

    final ad = _interstitialAd!;
    _interstitialAd = null;
    _isAdShowing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {},
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAdShowing = false;
        onAdDismissed();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isAdShowing = false;
        onAdDismissed();
        loadInterstitialAd();
        _showErrorDialog('Interstitial Show', error);
      },
    );
    ad.show();
  }
}
