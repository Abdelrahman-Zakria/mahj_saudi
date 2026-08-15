import 'package:flutter_bloc/flutter_bloc.dart';
import 'exams_state.dart';
import '../../../../domain/repositories/educational_repository.dart';

class ExamsCubit extends Cubit<ExamsState> {
  final EducationalRepository repository;

  ExamsCubit(this.repository) : super(ExamsInitial());

  Future<void> loadRootSemesters() async {
    emit(ExamsLoading());
    try {
      final items = await repository.getRootNodes();
      emit(ExamsLoaded(items));
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  Future<void> loadGrades(String semesterId) async {
    emit(ExamsLoading());
    try {
      final items = await repository.getChildren(semesterId);
      emit(ExamsLoaded(items));
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }

  Future<void> loadExamTopic(String gradeId) async {
    emit(ExamsLoading());
    try {
      final children = await repository.getChildren(gradeId);
      final examNode = children.where((n) => n.title.contains('نماذج الاختبارات')).firstOrNull;
      
      if (examNode != null) {
        final exams = await repository.getChildren(examNode.id);
        emit(ExamsLoaded(exams));
      } else {
        emit(const ExamsLoaded([]));
      }
    } catch (e) {
      emit(ExamsError(e.toString()));
    }
  }
}
