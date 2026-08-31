import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as dev;
import '../../main.dart';

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

    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      dev.log('IAP Global Stream Error: $error');
      _showError('خطأ في الاتصال بمتجر آبل');
    });
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      dev.log('IAP Event: ${purchaseDetails.productID} -> ${purchaseDetails.status}');
      
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoadingController.add(true);
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        dev.log('IAP Error Object: ${purchaseDetails.error}');
        _isLoadingController.add(false);
        _showError('فشلت العملية: ${purchaseDetails.error?.message ?? "خطأ غير معروف"}');
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _isLoadingController.add(false);
        dev.log('IAP: User canceled');
      } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                 purchaseDetails.status == PurchaseStatus.restored) {
        
        if (purchaseDetails.productID == removeAdsId) {
          await setAdFree(true);
          _showSuccess('تم تفعيل النسخة الاحترافية وإزالة الإعلانات!');
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
  }

  Future<void> buyAdRemoval() async {
    _isLoadingController.add(true);
    dev.log('IAP: Manual Buy Request for $removeAdsId');

    // Safety timeout to prevent stuck loader if Apple sheet fails to show
    Timer(const Duration(seconds: 25), () {
      _isLoadingController.add(false);
    });
    
    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        dev.log('IAP: isAvailable() returned false');
        _showError('خدمة الشراء غير متاحة حالياً على هذا الجهاز');
        _isLoadingController.add(false);
        return;
      }

      dev.log('IAP: Querying $removeAdsId...');
      const Set<String> kIds = {removeAdsId};
      final ProductDetailsResponse response = await _iap.queryProductDetails(kIds);

      if (response.error != null) {
        dev.log('IAP Query Error: ${response.error}');
        _showError('تعذر الاتصال بمتجر التطبيقات');
        _isLoadingController.add(false);
        return;
      }

      if (response.productDetails.isEmpty) {
        dev.log('IAP Error: Product details list is empty. Not found IDs: ${response.notFoundIDs}');
        _showError('لم يتم العثور على المنتج في المتجر. يرجى المحاولة لاحقاً.');
        _isLoadingController.add(false);
        return;
      }

      final ProductDetails productDetails = response.productDetails.first;
      dev.log('IAP: Product found! Price: ${productDetails.price}. Showing sheet...');
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // On iOS, this triggers the native system dialog
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
    } catch (e) {
      dev.log('IAP Exception: $e');
      _showError('حدث خطأ تقني: $e');
      _isLoadingController.add(false);
    }
  }

  void _showError(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'Cairo')),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> restorePurchases() async {
    _isLoadingController.add(true);
    try {
      dev.log('IAP: Requesting restore...');
      await _iap.restorePurchases();
    } catch (e) {
      dev.log('IAP Restore Error: $e');
      _isLoadingController.add(false);
      _showError('تعذر استعادة المشتريات حالياً');
    }
  }

  void dispose() {
    _subscription.cancel();
    _adFreeStatusController.close();
    _isLoadingController.close();
  }
}
