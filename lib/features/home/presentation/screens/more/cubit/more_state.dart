import 'package:equatable/equatable.dart';

abstract class MoreState extends Equatable {
  final bool notificationsEnabled;
  const MoreState({this.notificationsEnabled = true});
  @override
  List<Object?> get props => [notificationsEnabled];
}

class MoreInitial extends MoreState {
  const MoreInitial({super.notificationsEnabled});
}

class MoreUpdated extends MoreState {
  const MoreUpdated({required super.notificationsEnabled});
}
