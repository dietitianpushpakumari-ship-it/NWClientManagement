import 'package:flutter/material.dart';
// Note: flutter_markdown is imported here, ensuring correct usage.
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:nutricare_client_management/scheduler/dieititan_content_model.dart';
import 'package:nutricare_client_management/admin/custom_gradient_app_bar.dart';



class ContentDetailScreen extends StatelessWidget {
  final DietitianContentModel content;

  const ContentDetailScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: CustomGradientAppBar(
          title: Text(content.title),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Metadata ---
                Text(
                  'Type: ${content.postType.label} | Published: ${content.publishedAt.toString().substring(0, 10)}',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
      
                // --- Disease Tags ---
                Wrap(
                  spacing: 8.0,
                  children: content.diseaseTags.map((tag) => Chip(
                    label: Text(tag.label, style: const TextStyle(color: Colors.white)),
                    backgroundColor: tag.color,
                  )).toList(),
                ),
                const Divider(),
      
                // 🎯 FIX: Using standard MarkdownBody, which is the current non-deprecated approach.
                MarkdownBody(
                  data: content.content,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                    h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    p: const TextStyle(fontSize: 16, height: 1.5),
                    listBullet: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
      
                const Divider(height: 40),
      
                // --- General Tags ---
                Wrap(
                  spacing: 8.0,
                  children: content.generalTags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue.shade50,
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
