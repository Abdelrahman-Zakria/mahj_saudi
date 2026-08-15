import 'package:equatable/equatable.dart';
import '../../../../core/utils/string_utils.dart';

class Resource extends Equatable {
  final String type;
  final String url;

  const Resource({required this.type, required this.url});

  @override
  List<Object?> get props => [type, url];

  factory Resource.fromMap(Map<String, dynamic> map) {
    return Resource(
      type: map['type'] ?? '',
      url: map['url'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'url': url,
    };
  }
}

class EducationalNode extends Equatable {
  final String id;
  final String? parentId;
  final String title;
  final String url;
  final String kind;
  final List<Resource> resources;

  const EducationalNode({
    required this.id,
    this.parentId,
    required this.title,
    required this.url,
    required this.kind,
    this.resources = const [],
  });

  String get displayTitle => StringUtils.cleanArabicTitle(title);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parentId': parentId,
      'title': title,
      'url': url,
      'kind': kind,
      'resources': resources.map((e) => e.toMap()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, parentId, title, url, kind, resources];

  factory EducationalNode.fromMap(String id, Map<String, dynamic> map) {
    return EducationalNode(
      id: id,
      parentId: map['parentId'],
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      kind: map['kind'] ?? '',
      resources: (map['resources'] as List?)
              ?.map((e) => Resource.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}
