import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
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

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdFree = prefs.getBool('is_ad_free') ?? false;
    _adFreeStatusController.add(_isAdFree);

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      dev.log('IAP Error: $error');
    });
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        dev.log('Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        dev.log('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                 purchaseDetails.status == PurchaseStatus.restored) {
        
        dev.log('Purchase successful or restored: ${purchaseDetails.productID}');
        if (purchaseDetails.productID == removeAdsId) {
          await setAdFree(true);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
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
    final bool available = await _iap.isAvailable();
    if (!available) {
      dev.log('Store not available');
      return;
    }

    const Set<String> kIds = {removeAdsId};
    final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      dev.log('Product not found: ${response.notFoundIDs}');
    }

    if (response.productDetails.isNotEmpty) {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: response.productDetails.first);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } else {
      dev.log('No products available to buy');
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription.cancel();
    _adFreeStatusController.close();
  }
}
