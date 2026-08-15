import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/services/local_storage_service.dart';
import '../../widgets/semester_card.dart';
import '../content/content_page.dart';
import 'cubit/library_cubit.dart';
import 'cubit/library_state.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LibraryCubit(GetIt.I<LocalStorageService>())..loadLibrary(),
      child: const LibraryView(),
    );
  }
}

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مكتبتي التعليمية")),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            if (state is LibraryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LibraryError) {
              return Center(child: Text(state.message));
            }
            if (state is LibraryLoaded) {
              if (state.items.isEmpty) {
                return const Center(child: Text("لا يوجد أي عناصر محفوظة"));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final node = state.items[index];
                  return SemesterCard(
                    key: ValueKey("lib_${node.id}"),
                    title: node.title,
                    subtitle: "تم الحفظ بنجاح",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContentPage(
                            node: node,
                            parentId: node.id,
                            title: node.title,
                          ),
                        ),
                      ).then((_) {
                        if (context.mounted) {
                          context.read<LibraryCubit>().loadLibrary();
                        }
                      });
                    },
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
