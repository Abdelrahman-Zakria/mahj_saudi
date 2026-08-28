import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;

class IapService {
  static final IapService _instance = IapService._internal();
  factory IapService() => _instance;
  IapService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  static const String removeAdsId = 'remove_ads_premium';
  bool _isAdFree = false;
  bool get isAdFree => _isAdFree;

  final StreamController<bool> _adFreeStatusController = StreamController<bool>.broadcast();
  Stream<bool> get adFreeStatusStream => _adFreeStatusController.stream;

  final StreamController<bool> _isLoadingController = StreamController<bool>.broadcast();
  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdFree = prefs.getBool('is_ad_free') ?? false;
    _adFreeStatusController.add(_isAdFree);

    // --- iOS Specific Configuration ---
    if (Platform.isIOS) {
      try {
        final InAppPurchaseStoreKitPlatform iosPlatform = 
            InAppPurchasePlatform.instance as InAppPurchaseStoreKitPlatform;
        // Fallback to StoreKit 1 if StoreKit 2 is not working as expected
        // Version 3.3.0 uses StoreKit 2 by default
        dev.log('IAP: Forcing StoreKit 1 for compatibility');
        await iosPlatform.setTransactionObserver(SKPaymentQueueWrapper());
      } catch (e) {
        dev.log('IAP: Error setting iOS platform config: $e');
      }
    }

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      dev.log('IAP Stream Error: $error');
      _showError('خطأ في معالجة المشتريات: $error');
    });
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      dev.log('IAP: Purchase update received: ${purchaseDetails.productID} - ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        dev.log('IAP: Purchase pending...');
        _isLoadingController.add(true);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        dev.log('IAP: Purchase error: ${purchaseDetails.error}');
        _isLoadingController.add(false);
        _showError('حدث خطأ أثناء الشراء: ${purchaseDetails.error?.message}');
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        dev.log('IAP: Purchase canceled by user');
        _isLoadingController.add(false);
      } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                 purchaseDetails.status == PurchaseStatus.restored) {
        
        dev.log('IAP: Purchase successful or restored: ${purchaseDetails.productID}');
        if (purchaseDetails.productID == removeAdsId) {
          await setAdFree(true);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
        _isLoadingController.add(false);
      }
    }
  }

  Future<void> setAdFree(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_ad_free', status);
    _isAdFree = status;
    _adFreeStatusController.add(status);
    dev.log('Ad-free status updated to: $status');
  }

  Future<void> buyAdRemoval() async {
    _isLoadingController.add(true);
    dev.log('IAP: Initiating buyAdRemoval for $removeAdsId');
    
    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        dev.log('IAP: Store not available');
        _showError('متجر التطبيقات غير متاح حالياً');
        _isLoadingController.add(false);
        return;
      }

      const Set<String> kIds = {removeAdsId};
      dev.log('IAP: Querying product details for $removeAdsId');
      final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);

      if (response.notFoundIDs.isNotEmpty) {
        dev.log('IAP: Product not found in store: ${response.notFoundIDs}');
      }

      if (response.error != null) {
        dev.log('IAP Query Error: ${response.error}');
        _showError('خطأ في الاتصال بالمتجر: ${response.error?.message}');
        _isLoadingController.add(false);
        return;
      }

      if (response.productDetails.isNotEmpty) {
        final ProductDetails productDetails = response.productDetails.first;
        dev.log('IAP: Product found: ${productDetails.title} - ${productDetails.price}');
        
        final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
        
        // Use non-consumable for "Remove Ads"
        dev.log('IAP: Calling buyNonConsumable');
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        dev.log('IAP: No products available to buy (empty list returned)');
        _showError('لم يتم العثور على المنتج في المتجر. يرجى التأكد من إعدادات الحساب وتوفر الإنترنت.');
        _isLoadingController.add(false);
      }
    } catch (e) {
      dev.log('IAP Exception in buyAdRemoval: $e');
      _showError('حدث خطأ غير متوقع: $e');
      _isLoadingController.add(false);
    }
  }

  void _showError(String message) {
    dev.log('IAP User Error: $message');
    // Error logic handled by UI listening to streams if needed, 
    // or through a global messenger if available.
  }

  Future<void> restorePurchases() async {
    dev.log('IAP: Initiating restorePurchases');
    _isLoadingController.add(true);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      dev.log('IAP Restore Error: $e');
      _isLoadingController.add(false);
    }
  }

  void dispose() {
    _subscription.cancel();
    _adFreeStatusController.close();
    _isLoadingController.close();
  }
}

