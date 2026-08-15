import 'package:equatable/equatable.dart';
import '../../../../domain/entities/educational_node.dart';

abstract class ContentState extends Equatable {
  final bool isFavorite;
  const ContentState({this.isFavorite = false});
  @override
  List<Object?> get props => [isFavorite];
}

class ContentInitial extends ContentState {}
class ContentLoading extends ContentState {
  const ContentLoading({super.isFavorite});
}
class ContentLoaded extends ContentState {
  final List<EducationalNode> items;
  const ContentLoaded(this.items, {super.isFavorite});
  @override
  List<Object?> get props => [items, isFavorite];
}
class ContentError extends ContentState {
  final String message;
  const ContentError(this.message, {super.isFavorite});
  @override
  List<Object?> get props => [message, isFavorite];
}
