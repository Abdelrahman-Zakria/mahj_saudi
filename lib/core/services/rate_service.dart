import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class RateService {
  static final RateService _instance = RateService._internal();
  factory RateService() => _instance;
  RateService._internal();

  static const String _rateKey = 'has_rated_app';
  static const String appStoreUrl = 'https://apps.apple.com/sa/app/%D9%85%D9%86%D9%87%D8%AC%D9%8I-%D8%A7%D9%84%D8%B3%D8%B9%D9%88%D8%AF%D9%8A/id6801933753';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.mnhaj.saudi';

  Future<void> initRateTimer(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasRated = prefs.getBool(_rateKey) ?? false;

    if (!hasRated) {
      Timer(const Duration(minutes: 2), () {
        if (context.mounted) {
          _showRateDialog(context);
        }
      });
    }
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'تقييم التطبيق ⭐️',
            style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'هل يعجبك تطبيق منهجي؟ يسعدنا جداً تقييمك للتطبيق على المتجر لنتمكن من تطويره للأفضل.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لاحقاً', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_rateKey, true);
                
                final String url = Platform.isIOS ? appStoreUrl : playStoreUrl;
                final Uri uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('تقييم الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
