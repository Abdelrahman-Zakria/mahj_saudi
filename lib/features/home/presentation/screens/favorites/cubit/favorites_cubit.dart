import 'package:flutter_bloc/flutter_bloc.dart';
import 'favorites_state.dart';
import '../../../../../../core/services/local_storage_service.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  final LocalStorageService storage;

  FavoritesCubit(this.storage) : super(FavoritesInitial());

  void loadFavorites() {
    emit(FavoritesLoading());
    try {
      final items = storage.getFavorites();
      emit(FavoritesLoaded(items));
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }
}
