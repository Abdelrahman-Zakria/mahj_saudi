import 'package:equatable/equatable.dart';

abstract class PdfViewerState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  const PdfViewerState({this.isLoading = true, this.errorMessage});
  @override
  List<Object?> get props => [isLoading, errorMessage];
}

class PdfViewerInitial extends PdfViewerState {}
class PdfViewerLoading extends PdfViewerState {
  const PdfViewerLoading() : super(isLoading: true);
}
class PdfViewerLoaded extends PdfViewerState {
  const PdfViewerLoaded() : super(isLoading: false);
}
class PdfViewerError extends PdfViewerState {
  const PdfViewerError(String message) : super(isLoading: false, errorMessage: message);
}
