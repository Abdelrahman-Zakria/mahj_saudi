import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../../../core/services/ad_service.dart';
import '../../../../../../core/services/local_storage_service.dart';
import '../../../../../../core/services/notification_service.dart';
import 'timer_state.dart';

class TimerCubit extends Cubit<TimerState> {
  final LocalStorageService storage;
  final NotificationService notifications;

  TimerCubit({required this.storage, required this.notifications}) : super(const TimerInitial());

  void loadTimers() {
    emit(TimerLoading(state.timers));
    try {
      final timers = storage.getTimers();
      emit(TimerLoaded(timers));
    } catch (e) {
      emit(TimerError(e.toString(), state.timers));
    }
  }

  Future<void> addTimer({
    required String title,
    required String startTimeStr,
    required String endTimeStr,
    required DateTime startDt,
    required DateTime endDt,
  }) async {
    emit(TimerLoading(state.timers));
    try {
      // Save to storage
      await storage.saveTimer({
        'title': title,
        'start': startTimeStr,
        'end': endTimeStr,
      });

      // Schedule Dual System Alarms
      final timerId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 50000;
      final DateTime currentNow = DateTime.now();
      
      // Trigger AD on adding alarm
      GetIt.I<AdService>().showInterstitialAd(onAdDismissed: () {});

      if (startDt.isAfter(currentNow)) {
        await notifications.scheduleSystemAlarm(
          id: timerId,
          time: startDt,
          title: 'بدأ وقت المذاكرة: $title',
          body: 'حان الوقت للبدء في جلستك الدراسية.',
        );
      }
      
      if (endDt.isAfter(currentNow)) {
        await notifications.scheduleSystemAlarm(
          id: timerId + 10000,
          time: endDt,
          title: 'انتهى وقت المذاكرة: $title',
          body: 'لقد أتممت جلستك الدراسية. خذ قسطاً من الراحة!',
        );
      }

      final updatedTimers = storage.getTimers();
      emit(TimerActionSuccess("تم حفظ المنبه بنجاح", updatedTimers));
    } catch (e) {
      emit(TimerError(e.toString(), state.timers));
    }
  }

  Future<void> deleteTimer(int index) async {
    emit(TimerLoading(state.timers));
    try {
      // Trigger AD on removing alarm
      GetIt.I<AdService>().showInterstitialAd(onAdDismissed: () {});

      await storage.deleteTimer(index);
      final updatedTimers = storage.getTimers();
      emit(TimerActionSuccess("تم حذف المنبه", updatedTimers));
    } catch (e) {
      emit(TimerError(e.toString(), state.timers));
    }
  }

  Future<void> clearAll() async {
    emit(TimerLoading(state.timers));
    try {
      await storage.clearAllTimers();
      emit(const TimerActionSuccess("تم مسح جميع المواعيد", []));
    } catch (e) {
      emit(TimerError(e.toString(), state.timers));
    }
  }
}
