import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/services/local_storage_service.dart';
import '../../widgets/semester_card.dart';
import '../content/content_page.dart';
import 'cubit/favorites_cubit.dart';
import 'cubit/favorites_state.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavoritesCubit(GetIt.I<LocalStorageService>())..loadFavorites(),
      child: const FavoritesView(),
    );
  }
}

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("حقيبتي الدراسية")),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, state) {
            if (state is FavoritesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is FavoritesError) {
              return Center(child: Text(state.message));
            }
            if (state is FavoritesLoaded) {
              if (state.items.isEmpty) {
                return const Center(child: Text("لا يوجد عناصر في حقيبتك"));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final node = state.items[index];
                  return SemesterCard(
                    key: ValueKey("fav_${node.id}"),
                    title: node.title,
                    subtitle: "اضغط للمتابعة",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContentPage(
                            node: node,
                            parentId: node.parentId ?? node.id,
                            title: node.title,
                          ),
                        ),
                      ).then((_) {
                        if (context.mounted) {
                          context.read<FavoritesCubit>().loadFavorites();
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
