import 'dart:io';
import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String imagePath;

  const FullScreenImageView({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, // This extends content behind the app bar
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            constrained: false, // Allow content to be larger than the viewport
            child: Image.file(
              File(imagePath),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.white70,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Could not load image',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}