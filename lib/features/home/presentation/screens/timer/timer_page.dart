import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/local_storage_service.dart';
import '../../../../../core/services/notification_service.dart';
import 'cubit/timer_cubit.dart';
import 'cubit/timer_state.dart';

class TimerPage extends StatelessWidget {
  const TimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimerCubit(
        storage: GetIt.I<LocalStorageService>(),
        notifications: GetIt.I<NotificationService>(),
      )..loadTimers(),
      child: const TimerView(),
    );
  }
}

class TimerView extends StatelessWidget {
  const TimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("منبه المذاكرة"),
        actions: [
          BlocBuilder<TimerCubit, TimerState>(
            builder: (context, state) {
              if (state.timers.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _confirmClearAll(context),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocListener<TimerCubit, TimerState>(
        listener: (context, state) {
          if (state is TimerActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, textAlign: TextAlign.center),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is TimerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, textAlign: TextAlign.center),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocBuilder<TimerCubit, TimerState>(
            builder: (context, state) {
              final timers = state.timers;
              if (timers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, size: 80, color: AppTheme.primaryGreen),
                      const SizedBox(height: 16),
                      const Text("لا يوجد منبهات حالياً",
                          style: TextStyle(fontSize: 18, color: AppTheme.textLight)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _addTimer(context),
                        icon: const Icon(Icons.add),
                        label: const Text("إضافة وقت مذاكرة"),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: timers.length,
                itemBuilder: (context, index) {
                  final t = timers[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("من ${t['start']} إلى ${t['end']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Study", style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _confirmDeleteSingle(context, index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: BlocBuilder<TimerCubit, TimerState>(
        builder: (context, state) {
          if (state.timers.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () => _addTimer(context),
              backgroundColor: AppTheme.primaryGreen,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  void _addTimer(BuildContext context) async {
    final titleController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final cubit = context.read<TimerCubit>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (innerContext) => BlocProvider.value(
        value: cubit,
        child: StatefulBuilder(
          builder: (modalContext, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "إضافة وقت مذاكرة",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: "عنوان المنبه",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: modalContext,
                            initialTime: startTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setModalState(() => startTime = picked);
                          }
                        },
                        label: Text(startTime == null ? "وقت البدء" : startTime!.format(modalContext)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.timer_off_outlined),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: modalContext,
                            initialTime: endTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setModalState(() => endTime = picked);
                          }
                        },
                        label: Text(endTime == null ? "وقت الانتهاء" : endTime!.format(modalContext)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                BlocBuilder<TimerCubit, TimerState>(
                  builder: (context, state) {
                    final isLoading = state is TimerLoading;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isLoading ? null : () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          _showToast(context, "يرجى إدخال عنوان للمنبه", isError: true);
                          return;
                        }
                        if (startTime == null || endTime == null) {
                          _showToast(context, "يرجى اختيار الوقت", isError: true);
                          return;
                        }

                        final now = DateTime.now();
                        final startDt = DateTime(now.year, now.month, now.day, startTime!.hour, startTime!.minute);
                        final endDt = DateTime(now.year, now.month, now.day, endTime!.hour, endTime!.minute);

                        if (endDt.isBefore(startDt)) {
                          _showToast(context, "وقت الانتهاء لا يمكن أن يكون قبل وقت البدء", isError: true);
                          return;
                        }

                        await cubit.addTimer(
                          title: title,
                          startTimeStr: startTime!.format(context),
                          endTimeStr: endTime!.format(context),
                          startDt: startDt,
                          endDt: endDt,
                        );

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("حفظ المنبه", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSingle(BuildContext context, int index) {
    final cubit = context.read<TimerCubit>();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("حذف المنبه"),
          content: const Text("هل أنت متأكد من رغبتك في حذف هذا المنبه؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("إلغاء"),
            ),
            TextButton(
              onPressed: () {
                cubit.deleteTimer(index);
                Navigator.pop(context);
              },
              child: const Text("حذف", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    final cubit = context.read<TimerCubit>();
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text("حذف الكل"),
          content: const Text("هل أنت متأكد من حذف جميع المواعيد؟"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("لا"),
            ),
            TextButton(
              onPressed: () {
                cubit.clearAll();
                Navigator.pop(context);
              },
              child: const Text("نعم", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
