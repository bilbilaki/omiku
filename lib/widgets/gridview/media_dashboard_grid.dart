import 'package:flutter/material.dart';
import 'package:omiku/widgets/gridview/premium_media_card.dart';

class MediaDashboardGrid extends StatelessWidget {
  const MediaDashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03071E), // Ultra dark background setup
      appBar: AppBar(
        title: const Text('Media Universe', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0A1128),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.72, // Tighter ratio accommodating text configurations safely
        ),
        itemBuilder: (context, index) {
          // Mock collection reflecting your content types Mix
          final items = [
            {
              'id': 'book_1',
              'title': 'The Way of Kings',
              'overview': 'Roshar is a world of stone and storms. Uncanny tempests of incredible power sweep across the rocky terrain.',
              'imagePath': '[https://picsum.photos/id/11/600/900](https://picsum.photos/id/11/600/900)', // Web resource
              'badgeText': 'Ch. 42',
              'rating': 9.2,
              'progress': 0.65,
            },
            {
              'id': 'series_1',
              'title': 'Stranger Things',
              'overview': 'When a young boy vanishes, a small town uncovers a mystery involving secret experiments and terrifying forces.',
              'imagePath': 'assets/images/stranger_things.png', // Local application asset fallback
              'badgeText': 'S4 Ep.8',
              'rating': 8.7,
              'progress': 0.90,
            },
          ];

          if (index >= items.length) return const SizedBox.shrink();
          final data = items[index];

          return PremiumMediaCard(
            id: data['id'] as String,
            title: data['title'] as String,
            overview: data['overview'] as String,
            imagePath: data['imagePath'] as String,
            badgeText: data['badgeText'] as String?,
            rating: data['rating'] as double?,
            progress: data['progress'] as double,
            onTap: () {
              // Hero transition hooks safely into standard router push contexts seamlessly
            },
          );
        },
      ),
    );
  }
}