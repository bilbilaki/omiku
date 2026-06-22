import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

class LibraryDialog extends StatelessWidget {
  final TextEditingController seriesNameController;
  final TextEditingController descriptionController;
  final TextEditingController chapterNameController;
  final TextEditingController chapterNumController;
  final File coverImage;
  final VoidCallback onDone;
  const LibraryDialog({
    required this.onDone,
    required this.coverImage,
    required this.seriesNameController,
    required this.chapterNameController,
    required this.chapterNumController,
    required this.descriptionController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              width: 280.0,
              height: 280.0,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.white24,
                    child: Image(image: FileImage(coverImage)),
                  ),
                  SizedBox(height: 12),
                  // Text(
                  //   'Series Name',
                  //   style: TextStyle(
                  //     color: Colors.white,
                  //     fontWeight: FontWeight.bold,
                  //     fontSize: 16,
                  //   ),
                  // ),
                  // SizedBox(height: 1),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Series Name',
                      hintText: 'Enter your Series Name',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.name,
                    controller: seriesNameController,
                    onChanged: (value) {},
                  ),
                  SizedBox(height: 4),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Discription',
                      hintText: 'Enter your Series Discription',
                      prefixIcon: const Icon(Icons.message),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.multiline,
                    controller: seriesNameController,
                    onChanged: (value) {},
                  ),
                  SizedBox(height: 4),

                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Chapter Name',
                      hintText: 'Enter your Chapter Name',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.name,
                    controller: seriesNameController,
                    onChanged: (value) {},
                  ),
                  SizedBox(height: 4),

                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Chapter Number',
                      hintText: 'Enter your Chapter Number',
                      prefixIcon: const Icon(Icons.message),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    controller: seriesNameController,
                    onChanged: (value) {},
                  ),
                  SizedBox(height: 2),
                  ElevatedButton(
                    onPressed: () {
                      onDone();
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
