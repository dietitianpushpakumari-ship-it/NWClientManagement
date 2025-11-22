import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String? localPath;

  const FullScreenImageViewer({super.key, this.imageUrl, this.localPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: imageUrl != null
              ? Image.network(imageUrl!)
              : Image.file(File(localPath!)),
        ),
      ),
    );
  }
}