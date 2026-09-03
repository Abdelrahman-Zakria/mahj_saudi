import 'dart:io';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'more_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../core/services/local_storage_service.dart';
import '../../../../../../core/services/notification_service.dart';

class MoreCubit extends Cubit<MoreState> {
  final LocalStorageService storage;
  final NotificationService notifications;

  MoreCubit({required this.storage, required this.notifications})
    : super(
        MoreInitial(notificationsEnabled: storage.areNotificationsEnabled()),
      );

  void toggleNotifications(bool enabled) async {
    await storage.setNotificationsEnabled(enabled);
    if (!enabled) {
      await notifications.cancelAll();
    } else {
      await notifications.reInitialize();
    }
    emit(MoreUpdated(notificationsEnabled: enabled));
  }

  void shareApp({Rect? sharePositionOrigin}) {
    const String iosLink =
        'https://apps.apple.com/us/app/%D9%85%D9%86%D9%87%D8%AC%D9%8I-%D8%A7%D9%84%D8%B3%D8%B9%D9%88%D8%AF%D9%8A/id6801933753';
    const String androidLink =
        'https://play.google.com/store/apps/details?id=com.mo.mahj';

    final String link = Platform.isIOS ? iosLink : androidLink;
    final String message =
        'حمل تطبيق منهجي السعودي الآن واستمتع بكافة المناهج الدراسية مجاناً!\n\n$link';

    SharePlus.instance.share(
      ShareParams(text: message, sharePositionOrigin: sharePositionOrigin),
    );
  }

  Future<void> launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'monayef15@gmail.com',
      query: 'subject=استفسار بخصوص تطبيق منهجي السعودي',
    );
    if (!await launchUrl(emailLaunchUri)) {
      // Handle error
    }
  }

  Future<void> launchStore() async {
    const String iosLink =
        'https://apps.apple.com/us/app/%D9%85%D9%86%D9%87%D8%AC%D9%8I-%D8%A7%D9%84%D8%B3%D8%B9%D9%88%D8%AF%D9%8A/id6801933753';
    const String androidLink =
        'https://play.google.com/store/apps/details?id=com.mo.mahj';

    final String urlString = Platform.isIOS ? iosLink : androidLink;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }
}
