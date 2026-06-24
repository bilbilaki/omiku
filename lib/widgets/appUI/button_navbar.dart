import 'package:flutter/material.dart';
import 'package:omiku/widgets/voice_widget.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.shifting, // Ensures all labels are visible
      backgroundColor: AppColors.primaryBackground,
      selectedItemColor:  Color.fromARGB(255, 0, 72, 255),
      unselectedItemColor: AppColors.textSecondary,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedFontSize: 12.0,
      unselectedFontSize: 10.0,
      items:  [
        BottomNavigationBarItem(
          icon: Icon(Icons.movie),
          activeIcon: Icon(Icons.movie_edit),
          label: 'Movies',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.tv),
          activeIcon: Icon(Icons.tv_sharp),
          label: 'TvSeries',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_border_outlined),
          activeIcon: Icon(Icons.star_border_sharp),
          label: 'Anime',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category),
          activeIcon: Icon(Icons.category_sharp),
          label: 'Manga',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_border_outlined),
          activeIcon: Icon(Icons.star_border_sharp),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_add),
          activeIcon: Icon(Icons.bookmark),
          label: 'WatchList',
        )
      ],
    );
  }
}