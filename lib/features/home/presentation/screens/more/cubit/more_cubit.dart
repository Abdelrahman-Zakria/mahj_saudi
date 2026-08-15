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
      : super(MoreInitial(notificationsEnabled: storage.areNotificationsEnabled()));

  void toggleNotifications(bool enabled) async {
    await storage.setNotificationsEnabled(enabled);
    if (!enabled) {
      await notifications.cancelAll();
    } else {
      await notifications.reInitialize();
    }
    emit(MoreUpdated(notificationsEnabled: enabled));
  }

  void shareApp() {
    Share.share('حمل تطبيق منهجي السعودي الآن واستمتع بكافة المناهج الدراسية مجاناً!');
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
    final Uri url = Uri.parse('https://play.google.com/store/apps/details?id=com.mnhaj.saudi');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle error
    }
  }
}
