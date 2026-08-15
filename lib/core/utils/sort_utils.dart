class SortUtils {
  static final Map<String, int> _orderMap = {
    // Semesters
    "الفصل الدراسي الاول": 1,
    "الفصل الدراسي الثاني": 2,
    "الفصل الدراسي الثالث": 3,
    
    // Grades - Primary
    "الصف الاول الابتدائي": 10,
    "الصف الثاني الابتدائي": 11,
    "الصف الثالث الابتدائي": 12,
    "الصف الرابع الابتدائي": 13,
    "الصف الخامس الابتدائي": 14,
    "الصف السادس الابتدائي": 15,
    
    // Grades - Middle
    "الصف الاول المتوسط": 20,
    "الصف الثاني المتوسط": 21,
    "الصف الثالث المتوسط": 22,
    
    // Grades - Secondary
    "الصف الاول الثانوي": 30,
    "الصف الثاني الثانوي": 31,
    "الصف الثالث الثانوي": 32,
  };

  static int getSortWeight(String title) {
    // Exact match
    if (_orderMap.containsKey(title)) return _orderMap[title]!;
    
    // Partial match (to handle minor variations or trailing text)
    for (var entry in _orderMap.entries) {
      if (title.contains(entry.key)) return entry.value;
    }
    
    return 999; // Default for unknown items
  }
}
