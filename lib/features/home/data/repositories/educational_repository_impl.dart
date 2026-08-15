import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/educational_node.dart';
import '../../domain/repositories/educational_repository.dart';
import '../../../../core/utils/sort_utils.dart';

class EducationalRepositoryImpl implements EducationalRepository {
  final FirebaseFirestore firestore;

  EducationalRepositoryImpl(this.firestore);

  @override
  Future<List<EducationalNode>> getRootNodes() async {
    final snapshot = await firestore
        .collection('nodes')
        .where('kind', isEqualTo: 'semester')
        .get();
    
    final nodes = snapshot.docs
        .map((doc) => EducationalNode.fromMap(doc.id, doc.data()))
        .toList();

    // Custom sorting for Semesters
    nodes.sort((a, b) => SortUtils.getSortWeight(a.title).compareTo(SortUtils.getSortWeight(b.title)));
    
    return nodes;
  }

  @override
  Future<List<EducationalNode>> getChildren(String parentId) async {
    final snapshot = await firestore
        .collection('nodes')
        .where('parentId', isEqualTo: parentId)
        .get();
        
    final nodes = snapshot.docs
        .map((doc) => EducationalNode.fromMap(doc.id, doc.data()))
        .toList();

    // Custom sorting for Grades and general items
    nodes.sort((a, b) {
      final weightA = SortUtils.getSortWeight(a.title);
      final weightB = SortUtils.getSortWeight(b.title);
      
      // If both have specific weights (like grades), use weights
      if (weightA != 999 || weightB != 999) {
        return weightA.compareTo(weightB);
      }
      
      // Fallback to title sorting for subjects/lessons
      return a.title.compareTo(b.title);
    });
    
    return nodes;
  }

  @override
  Future<List<EducationalNode>> getExams() async {
    final snapshot = await firestore
        .collection('nodes')
        .where('title', isEqualTo: 'نماذج الاختبارات')
        .get();
        
    final nodes = snapshot.docs
        .map((doc) => EducationalNode.fromMap(doc.id, doc.data()))
        .toList();
        
    return nodes;
  }
}
