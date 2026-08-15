import 'package:flutter_bloc/flutter_bloc.dart';
import 'notifications_state.dart';
import '../../../../../../core/services/local_storage_service.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final LocalStorageService storage;

  NotificationsCubit(this.storage) : super(NotificationsInitial());

  void loadNotifications() {
    emit(NotificationsLoading());
    try {
      final items = storage.getNotificationHistory();
      emit(NotificationsLoaded(items));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> clearAll() async {
    await storage.clearNotificationHistory();
    emit(const NotificationsLoaded([]));
  }
}
