import 'package:equatable/equatable.dart';
import '../../../../domain/entities/educational_node.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();
  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {}
class LibraryLoading extends LibraryState {}
class LibraryLoaded extends LibraryState {
  final List<EducationalNode> items;
  const LibraryLoaded(this.items);
  @override
  List<Object?> get props => [items];
}
class LibraryError extends LibraryState {
  final String message;
  const LibraryError(this.message);
  @override
  List<Object?> get props => [message];
}
