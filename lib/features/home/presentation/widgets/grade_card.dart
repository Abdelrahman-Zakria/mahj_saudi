import 'package:flutter/material.dart';
import 'package:mahj_saudi/core/theme/app_theme.dart';
import '../../domain/entities/educational_node.dart';

class GradeCard extends StatelessWidget {
  final EducationalNode grade;
  final VoidCallback onTap;

  const GradeCard({
    super.key,
    required this.grade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getIconForGrade(grade.title),
                    size: 45,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
              child: Text(
                grade.displayTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForGrade(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains("ابتدائي")) return Icons.face;
    if (lowerTitle.contains("متوسط") || lowerTitle.contains("إعدادي")) return Icons.school_rounded;
    if (lowerTitle.contains("ثانوي")) return Icons.auto_stories_rounded;
    return Icons.menu_book_rounded;
  }
}
