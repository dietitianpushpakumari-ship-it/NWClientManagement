import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:nutricare_client_management/scheduler/dieititan_content_model.dart';

class ContentDetailScreen extends StatelessWidget {
  final DietitianContentModel content;
  const ContentDetailScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            expandedHeight: 100,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(content.title, style: const TextStyle(color: Colors.black87, fontSize: 16)),
              centerTitle: true,
            ),
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Chip(label: Text(content.postType.label), backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1), labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                    const Spacer(),
                    Text(DateFormat('dd MMM yyyy').format(content.publishedAt), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 20),
                MarkdownBody(data: content.content, styleSheet: MarkdownStyleSheet(h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), p: const TextStyle(fontSize: 16, height: 1.6))),
                const SizedBox(height: 40),
                const Divider(),
                Wrap(spacing: 8, children: content.generalTags.map((t) => Chip(label: Text("#$t"), backgroundColor: Colors.grey.shade100)).toList())
              ]),
            ),
          )
        ],
      ),
    );
  }
}