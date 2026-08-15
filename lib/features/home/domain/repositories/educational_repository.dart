import '../entities/educational_node.dart';

abstract class EducationalRepository {
  Future<List<EducationalNode>> getRootNodes();
  Future<List<EducationalNode>> getChildren(String parentId);
  Future<List<EducationalNode>> getExams();
}
