import 'package:equatable/equatable.dart';

abstract class TimerState extends Equatable {
  final List<Map<String, dynamic>> timers;
  const TimerState(this.timers);

  @override
  List<Object?> get props => [timers];
}

class TimerInitial extends TimerState {
  const TimerInitial() : super(const []);
}

class TimerLoading extends TimerState {
  const TimerLoading(super.timers);
}

class TimerLoaded extends TimerState {
  const TimerLoaded(super.timers);
}

class TimerError extends TimerState {
  final String message;
  const TimerError(this.message, super.timers);

  @override
  List<Object?> get props => [message, timers];
}

class TimerActionSuccess extends TimerState {
  final String message;
  const TimerActionSuccess(this.message, super.timers);

  @override
  List<Object?> get props => [message, timers];
}
