class StringUtils {
  static String cleanArabicTitle(String title) {
    if (title.isEmpty) return title;
    
    // Normalize string for comparison (handling Hamza variations)
    String normalize(String s) {
      return s
          .replaceAll('أ', 'ا')
          .replaceAll('إ', 'ا')
          .replaceAll('آ', 'ا')
          .trim();
    }

    String cleaned = title.trim();
    final normalizedTitle = normalize(cleaned);
    
    // List of common badges/prefixes that get duplicated during scraping
    final prefixes = ["الحل", "شرح", "تحضير", "توزيع", "اختبار", "كتاب", "أوراق", "نموذج"];
    
    for (var p in prefixes) {
      final normP = normalize(p);
      
      // Case 1: Duplication with Hamza variations like "أوراقاوراق"
      // We check if the start of the title normalized matches the prefix normalized TWICE
      if (normalizedTitle.startsWith("$normP$normP")) {
        // We remove the length of the original prefix
        cleaned = cleaned.substring(p.length).trim();
      }
      
      // Case 2: Badge "الحل" followed by "حل"
      if (normP == "الحل" && normalizedTitle.startsWith("الحلحل")) {
        cleaned = cleaned.substring(3).trim(); // Remove "الحل"
      }

      // Case 3: Badge followed by AL- prefix like "اختبارالاختبار"
      if (normalizedTitle.startsWith("$normPال$normP")) {
        cleaned = cleaned.substring(p.length).trim();
      }
    }
    
    // Final check for general first-word duplication with normalization
    final words = cleaned.split(' ');
    if (words.length > 1) {
      if (normalize(words[0]) == normalize(words[1])) {
        // Only if first word is a known prefix
        if (prefixes.any((p) => normalize(p) == normalize(words[0]))) {
          cleaned = words.sublist(1).join(' ');
        }
      }
    }
    
    return cleaned.trim();
  }
}
