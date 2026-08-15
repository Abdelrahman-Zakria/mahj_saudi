import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubit/exams_cubit.dart';
import 'cubit/exams_state.dart';
import '../../../data/repositories/educational_repository_impl.dart';
import '../../widgets/semester_card.dart';
import '../content/content_page.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExamsCubit(
        context.read<EducationalRepositoryImpl>(),
      )..loadRootSemesters(),
      child: Scaffold(
        appBar: AppBar(title: const Text("نماذج الاختبارات")),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "اختر الفصل الدراسي لتصفح نماذج اختبارات كل فصل وإضافتها بسهولة إلى مكتبتك.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              Expanded(
                child: BlocBuilder<ExamsCubit, ExamsState>(
                  builder: (context, state) {
                    if (state is ExamsLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ExamsLoaded) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final semester = state.items[index];
                          return SemesterCard(
                            title: "اختبارات ${semester.title}",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExamGradesPage(
                                    semesterId: semester.id,
                                    semesterTitle: semester.title,
                                    repository: context.read<EducationalRepositoryImpl>(),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExamGradesPage extends StatelessWidget {
  final String semesterId;
  final String semesterTitle;
  final EducationalRepositoryImpl repository;

  const ExamGradesPage({
    super.key, 
    required this.semesterId, 
    required this.semesterTitle,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExamsCubit(repository)..loadGrades(semesterId),
      child: Scaffold(
        appBar: AppBar(title: Text("اختبارات $semesterTitle")),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocBuilder<ExamsCubit, ExamsState>(
            builder: (context, state) {
              if (state is ExamsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ExamsLoaded) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final grade = state.items[index];
                    return SemesterCard(
                      title: "اختبارات ${grade.displayTitle}",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExamFinalListPage(
                              gradeId: grade.id,
                              gradeTitle: grade.title,
                              repository: repository,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

class ExamFinalListPage extends StatelessWidget {
  final String gradeId;
  final String gradeTitle;
  final EducationalRepositoryImpl repository;

  const ExamFinalListPage({
    super.key, 
    required this.gradeId, 
    required this.gradeTitle,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExamsCubit(repository)..loadExamTopic(gradeId),
      child: Scaffold(
        appBar: AppBar(title: Text("اختبارات $gradeTitle")),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocBuilder<ExamsCubit, ExamsState>(
            builder: (context, state) {
              if (state is ExamsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ExamsLoaded) {
                 if (state.items.isEmpty) {
                   return const Center(child: Text("لا توجد اختبارات حالياً لهذه المرحلة"));
                 }
                 return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return SemesterCard(
                      title: item.title,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContentPage(
                              node: item,
                              parentId: item.id,
                              title: item.title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
