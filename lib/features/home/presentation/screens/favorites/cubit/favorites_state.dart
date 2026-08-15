import 'package:equatable/equatable.dart';
import '../../../../domain/entities/educational_node.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}
class FavoritesLoading extends FavoritesState {}
class FavoritesLoaded extends FavoritesState {
  final List<EducationalNode> items;
  const FavoritesLoaded(this.items);
  @override
  List<Object?> get props => [items];
}
class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);
  @override
  List<Object?> get props => [message];
}
