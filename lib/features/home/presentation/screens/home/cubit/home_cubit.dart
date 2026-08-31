import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../../../../domain/repositories/educational_repository.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

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

  void shareApp({Rect? sharePositionOrigin}) {
    const String iosLink = 'https://apps.apple.com/us/app/%D9%85%D9%86%D9%87%D8%AC%D9%8I-%D8%A7%D9%84%D8%B3%D8%B9%D9%88%D8%AF%D9%8A/id6801933753';
    const String androidLink = 'https://play.google.com/store/apps/details?id=com.mo.mahj';
    
    final String link = Platform.isIOS ? iosLink : androidLink;
    final String message = 'حمل تطبيق منهجي السعودي الآن واستمتع بكافة المناهج الدراسية مجاناً!\n\n$link';
    
    Share.share(
      message,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
