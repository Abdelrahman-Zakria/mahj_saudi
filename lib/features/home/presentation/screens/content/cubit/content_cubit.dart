import 'package:flutter_bloc/flutter_bloc.dart';
import 'content_state.dart';
import '../../../../domain/repositories/educational_repository.dart';
import '../../../../../../core/services/local_storage_service.dart';
import '../../../../domain/entities/educational_node.dart';

class ContentCubit extends Cubit<ContentState> {
  final EducationalRepository repository;
  final LocalStorageService storage;

  ContentCubit({required this.repository, required this.storage}) : super(ContentInitial());

  Future<void> loadItems(String parentId, String? nodeId) async {
    final bool isFav = nodeId != null && storage.isFavorite(nodeId);
    emit(ContentLoading(isFavorite: isFav));
    try {
      final items = await repository.getChildren(parentId);
      emit(ContentLoaded(items, isFavorite: isFav));
    } catch (e) {
      emit(ContentError(e.toString(), isFavorite: isFav));
    }
  }

  Future<void> toggleFavorite(EducationalNode node) async {
    await storage.toggleFavorite(node);
    final isFav = storage.isFavorite(node.id);
    
    // We emit the same list but with a new favorite state to trigger UI update
    if (state is ContentLoaded) {
      emit(ContentLoaded((state as ContentLoaded).items, isFavorite: isFav));
    } else if (state is ContentLoading) {
      emit(ContentLoading(isFavorite: isFav));
    } else if (state is ContentError) {
      emit(ContentError((state as ContentError).message, isFavorite: isFav));
    }
  }

  Future<void> saveToLibrary(EducationalNode node) async {
    await storage.saveToLibrary(node);
  }
}
