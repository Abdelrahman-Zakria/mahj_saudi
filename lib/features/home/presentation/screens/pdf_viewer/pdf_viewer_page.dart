import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'cubit/pdf_viewer_cubit.dart';
import 'cubit/pdf_viewer_state.dart';

class PdfViewerPage extends StatelessWidget {
  final String url;
  final String title;

  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PdfViewerCubit(),
      child: PdfViewerView(url: url, title: title),
    );
  }
}

class PdfViewerView extends StatelessWidget {
  final String url;
  final String title;

  PdfViewerView({super.key, required this.url, required this.title});

  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: SfPdfViewer.network(
              Uri.parse(url).toString(),
              key: _pdfViewerKey,
              onDocumentLoaded: (details) {
                context.read<PdfViewerCubit>().setLoaded();
              },
              onDocumentLoadFailed: (details) {
                context.read<PdfViewerCubit>().setError('فشل تحميل الملف: ${details.description}');
              },
            ),
          ),
          BlocConsumer<PdfViewerCubit, PdfViewerState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
            },
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
