import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahj_saudi/features/home/presentation/widgets/grade_card.dart';
import 'package:mahj_saudi/features/home/presentation/widgets/semester_card.dart';
import 'package:mahj_saudi/features/home/presentation/widgets/resource_viewer.dart';
import 'package:mahj_saudi/features/home/data/repositories/educational_repository_impl.dart';
import 'package:mahj_saudi/features/home/domain/entities/educational_node.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../../core/services/local_storage_service.dart';
import '../../../../../core/services/ad_service.dart';
import 'package:get_it/get_it.dart';
import 'cubit/content_cubit.dart';
import 'cubit/content_state.dart';

class ContentPage extends StatelessWidget {
  final EducationalNode? node;
  final String parentId;
  final String title;

  const ContentPage({super.key, this.node, required this.parentId, required this.title});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContentCubit(
        repository: context.read<EducationalRepositoryImpl>(),
        storage: GetIt.I<LocalStorageService>(),
      )..loadItems(parentId, node?.id),
      child: ContentView(node: node, parentId: parentId, title: title),
    );
  }
}

class ContentView extends StatelessWidget {
  final EducationalNode? node;
  final String parentId;
  final String title;

  const ContentView({super.key, this.node, required this.parentId, required this.title});

  @override
  Widget build(BuildContext context) {
    final pdfRes = node?.resources.where((r) => r.type == 'pdf').firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(node?.displayTitle ?? title),
        actions: [
          if (node != null) ...[
            BlocBuilder<ContentCubit, ContentState>(
              buildWhen: (previous, current) => previous.isFavorite != current.isFavorite,
              builder: (context, state) {
                return IconButton(
                  icon: Icon(state.isFavorite ? Icons.favorite : Icons.favorite_border, color: Colors.red),
                  onPressed: () {
                    GetIt.I<AdService>().showInterstitialAd(
                      onAdDismissed: () => context.read<ContentCubit>().toggleFavorite(node!),
                    );
                  },
                );
              },
            ),
            if (pdfRes != null)
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  GetIt.I<AdService>().showInterstitialAd(
                    onAdDismissed: () async {
                      await context.read<ContentCubit>().saveToLibrary(node!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("تمت الإضافة إلى مكتبتي")),
                        );
                      }
                    },
                  );
                },
              ),
          ]
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            if (pdfRes != null)
              Expanded(child: _buildEmbeddedPdf(pdfRes.url))
            else if (node != null && node!.resources.isNotEmpty)
              ResourceViewer(node: node!),
            
            if (pdfRes == null)
              Expanded(
                child: BlocBuilder<ContentCubit, ContentState>(
                  builder: (context, state) {
                    if (state is ContentLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ContentError) {
                      return Center(child: Text(state.message));
                    }
                    if (state is ContentLoaded) {
                      if (state.items.isEmpty) {
                        if (node == null || node!.resources.isEmpty) {
                          return const Center(child: Text("لا توجد محتويات حالياً"));
                        }
                        return const SizedBox();
                      }
                      
                      final firstItem = state.items.first;
                      
                      if (firstItem.kind == 'grade') {
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) => GradeCard(
                            grade: state.items[index],
                            onTap: () => _navigate(context, state.items[index]),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length,
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final bool hasResources = item.resources.isNotEmpty;

                          return SemesterCard(
                            title: item.title,
                            subtitle: hasResources ? "محتوى تعليمي متوفر" : "اضغط للمتابعة",
                            onTap: () => _navigate(context, item),
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
    );
  }

  Widget _buildEmbeddedPdf(String url) {
    final encodedUrl = Uri.parse(url).toString();
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SfPdfViewer.network(
        encodedUrl,
        canShowScrollHead: true,
        canShowPaginationDialog: true,
      ),
    );
  }

  void _navigate(BuildContext context, EducationalNode node) {
    _performNavigation(context, node);
  }

  void _performNavigation(BuildContext context, EducationalNode node) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentPage(
          node: node,
          parentId: node.id,
          title: node.title,
        ),
      ),
    );
  }
}
