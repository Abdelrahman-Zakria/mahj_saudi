import 'package:flutter_bloc/flutter_bloc.dart';
import 'library_state.dart';
import '../../../../../../core/services/local_storage_service.dart';

class LibraryCubit extends Cubit<LibraryState> {
  final LocalStorageService storage;

  LibraryCubit(this.storage) : super(LibraryInitial());

  void loadLibrary() {
    emit(LibraryLoading());
    try {
      final items = storage.getLibraryNodes();
      emit(LibraryLoaded(items));
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }
}
