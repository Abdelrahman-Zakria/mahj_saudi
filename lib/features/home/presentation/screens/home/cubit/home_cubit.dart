import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../../../domain/repositories/educational_repository.dart';
import 'package:share_plus/share_plus.dart';

class HomeCubit extends Cubit<HomeState> {
  final EducationalRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> loadRootSemesters() async {
    emit(HomeLoading());
    try {
      final items = await repository.getRootNodes();
      emit(HomeLoaded(items));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void shareApp() {
    Share.share('حمل تطبيق منهجي السعودي الآن واستمتع بكافة المناهج الدراسية مجاناً!');
  }
}
