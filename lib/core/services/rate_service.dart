import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../theme/app_theme.dart';

class RateService {
  static final RateService _instance = RateService._internal();
  factory RateService() => _instance;
  RateService._internal();

  static const Duration rateInterval = Duration(minutes: 2);
  static const Duration firstRateDelay = Duration(seconds: 10);
  static const String appStoreId = '6801933753';

  Timer? _firstRateTimer;
  Timer? _rateTimer;
  bool _isDialogShowing = false;

  void initRateTimer(BuildContext context) {
    _firstRateTimer?.cancel();
    _rateTimer?.cancel();

    _firstRateTimer = Timer(firstRateDelay, () {
      if (context.mounted && !_isDialogShowing) {
        _showRateDialog(context);
      }
    });

    _rateTimer = Timer.periodic(rateInterval, (_) {
      if (context.mounted && !_isDialogShowing) {
        _showRateDialog(context);
      }
    });
  }

  void _showRateDialog(BuildContext context) {
    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppTheme.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'قيّم تطبيق منهجي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 30),
                  Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 30),
                  Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 30),
                  Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 30),
                  Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 30),
                ],
              ),
              SizedBox(height: 14),
              Text(
                'إذا أعجبك التطبيق، تقييمك يساعدنا نطوره ونوصله لطلاب أكثر.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 17,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'لاحقاً',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await requestNativeReview();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'تقييم الآن',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _isDialogShowing = false);
  }

  Future<void> requestNativeReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      await inAppReview.openStoreListing(appStoreId: appStoreId);
    }
  }

  void dispose() {
    _firstRateTimer?.cancel();
    _rateTimer?.cancel();
  }
}
