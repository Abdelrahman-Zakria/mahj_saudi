import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/educational_node.dart';
import '../screens/pdf_viewer/pdf_viewer_page.dart';

class ResourceViewer extends StatelessWidget {
  final EducationalNode node;

  const ResourceViewer({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    if (node.resources.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          Text(
            "المصادر المتاحة:",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: node.resources.map((res) => _buildResourceChip(context, res)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceChip(BuildContext context, Resource res) {
    IconData icon;
    String label;
    Color color;

    switch (res.type) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        label = 'PDF';
        color = Colors.red.shade700;
        break;
      case 'youtube':
        icon = Icons.play_circle_fill;
        label = 'فيديو';
        color = Colors.red;
        break;
      case 'ien':
        icon = Icons.auto_stories;
        label = 'بوابة عين';
        color = Colors.blue;
        break;
      case 'madrasati':
        icon = Icons.school;
        label = 'مدرستي';
        color = Colors.green;
        break;
      case 'viewer':
        icon = Icons.remove_red_eye;
        label = 'عرض';
        color = Colors.orange;
        break;
      default:
        icon = Icons.link;
        label = 'رابط';
        color = Colors.grey;
    }

    return ActionChip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      onPressed: () {
        if (res.type == 'pdf') {
          _openPdf(context, res.url);
        } else {
          _launchURL(context, res.url);
        }
      },
    );
  }

  void _openPdf(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerPage(
          url: url,
          title: node.displayTitle,
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر فتح الرابط')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }
}
