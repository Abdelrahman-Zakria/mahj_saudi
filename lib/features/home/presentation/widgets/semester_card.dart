import 'package:flutter/material.dart';
import 'package:mahj_saudi/core/theme/app_theme.dart';
import 'package:mahj_saudi/core/utils/string_utils.dart';

class SemesterCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SemesterCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanTitle = StringUtils.cleanArabicTitle(title);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.accentGreen, AppTheme.primaryGreen],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha:0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          cleanTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          subtitle ?? "اضغط للوصول إلى المواد الدراسية",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onTap: onTap,
      ),
    );
  }
}
