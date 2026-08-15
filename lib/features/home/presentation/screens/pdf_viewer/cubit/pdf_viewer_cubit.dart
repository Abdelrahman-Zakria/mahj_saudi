import 'package:flutter_bloc/flutter_bloc.dart';
import 'pdf_viewer_state.dart';

class PdfViewerCubit extends Cubit<PdfViewerState> {
  PdfViewerCubit() : super(PdfViewerInitial());

  void setLoaded() {
    emit(const PdfViewerLoaded());
  }

  void setError(String message) {
    emit(PdfViewerError(message));
  }
}
