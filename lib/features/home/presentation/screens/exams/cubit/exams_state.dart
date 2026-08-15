import 'package:equatable/equatable.dart';
import '../../../../domain/entities/educational_node.dart';

abstract class ExamsState extends Equatable {
  const ExamsState();
  @override
  List<Object?> get props => [];
}

class ExamsInitial extends ExamsState {}
class ExamsLoading extends ExamsState {}
class ExamsLoaded extends ExamsState {
  final List<EducationalNode> items;
  const ExamsLoaded(this.items);
  @override
  List<Object?> get props => [items];
}
class ExamsError extends ExamsState {
  final String message;
  const ExamsError(this.message);
  @override
  List<Object?> get props => [message];
}
