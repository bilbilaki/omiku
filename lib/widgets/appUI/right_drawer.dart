import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omiku/providers/app_state.dart';
import 'package:omiku/utils/ex_ap_color.dart';
import 'package:omiku/utils/haptic.dart';

class RightNavigationPanel extends ConsumerWidget {
  final bool isMobileLayout;
  final bool isCollapsed; // Only relevant for desktop

  const RightNavigationPanel({
    super.key,
    required this.isMobileLayout,
    required this.isCollapsed, // Pass collapsed state
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showText =
        !isCollapsed || isMobileLayout; // Determine when to show text

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header / Logo ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: isCollapsed && !isMobileLayout
              ? IconButton(
                  // Icon when collapsed
                  icon: const Icon(
                    Icons.interests_rounded,
                  ), // Use a relevant icon
                  onPressed: () {
                    // Maybe expand sidebar on icon click?
                    ref.read(rightSidebarCollapsedProvider.notifier).state = false;
                  },
                  color: Colors.grey[300],
                )
              : Row(
                  // Logo/Title and potentially a collapse button when expanded
                  children: [
                    Icon(
                      Icons.interests_rounded,
                      color: Colors.blue[300],
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    // Show collapse button only when expanded on desktop
                    if (!isCollapsed && !isMobileLayout)
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: () {},
//                             ref.read(sidebarCollapsedProvider.notifier).state =
           //                     true,
                        tooltip: 'Collapse sidebar',
                        color: Colors.grey[400],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
        ),

        // --- New Chat Button ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: isCollapsed && !isMobileLayout
              ? IconButton(
                  icon: const Icon(Icons.add_comment_outlined),
                  onPressed: () {},
                  color: Colors.grey[300],
                )
              : ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(''),
                  onPressed: () {
                    if (isMobileLayout) Navigator.pop(context); // Close drawer
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40), // Full width
                    // Use theme colors or define explicitly
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    alignment: Alignment.centerLeft, // Align icon/text left
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
        ),

        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
         

              // _buildNavigationItem(
              //   context,
              //   ref,
              //   icon: Icons.tv,
              //   title: 'IPTV Player',
              //   showText: showText,
              //   onTap: () => _navigateTo(context, IptvScreen(), isMobileLayout),
              // ),

              // _buildNavigationItem(
              //   context,
              //   ref,
              //   icon: Icons.assistant,
              //   title: 'AI Browser OpenAI',
              //   showText: showText,
              //   onTap: () {}
//               //       _navigateTo(context, AiBrowserApp(), isMobileLayout),
              // ),

          
        
              _buildNavigationItem(
                context,
                ref,
                icon: Icons.movie_creation,
                title: 'Movies',
                showText: showText,
                onTap: () {}
//  _navigateTo(
   //               context,
     //             AnimeGridScreen(typec: "movie"),
       //           isMobileLayout,
         //       ),
              ),
              _buildNavigationItem(
                context,
                ref,
                icon: Icons.live_tv_rounded,
                title: 'TV Series',
                showText: showText,
                onTap: () {}
//  _navigateTo(
   //               context,
     //              AnimeGridScreen(typec: "tvseries"),
       //           isMobileLayout,
         //       ),
              ),
              _buildNavigationItem(
                context,
                ref,
                icon: Icons.movie_outlined,
                title: 'Anime',
                showText: showText,

                onTap: () {}
//  _navigateTo(
   //               context,
     //              AnimeGridScreen(typec: "anime"),
       //           isMobileLayout,
         //       ),
              ),
              _buildNavigationItem(
                context,
                ref,
                icon: Icons.category_outlined,
                title: 'Genres',
                showText: showText,
                onTap: () {}
//  _navigateTo(
   //               context,
     //             const GenreListScreen(),
      //            isMobileLayout,
        //        ),
              ),
             Divider(color: AppColors.dividerColor, height: 1),

              _buildNavigationItem(
                context,
                ref,
                icon: Icons.watch_later_outlined,
                title: 'Watchlist',
                showText: showText,
                onTap: () {}
//  _navigateTo(
   //               context,
     //             const WatchlistScreen(),
       //           isMobileLayout,
         //       ),
              ),
              _buildNavigationItem(
                context,
                ref,
                icon: Icons.favorite_border_sharp,
                title: 'Favorites',
                showText: showText,
                onTap: () {}
//  _navigateTo(
   //               context,
     //             const FavoritesScreen(),
       //           isMobileLayout,
         //       ),
              ),

              _buildNavigationItem(
                context,
                ref,
                icon: Icons.spoke_outlined,
                title: 'Crawler Tools',
                showText: showText,
                onTap: () {}
//  _navigateTo(
  //                context,
    //              const CrawlerHomePage4(),
        //          isMobileLayout,
      //          ),
              ),
               Divider(color: AppColors.dividerColor, height: 1),
              const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 8)),
              if (showText) _buildSectionHeader('Subscriptions'),
              _buildNavigationItem(
                context,
                ref,
                icon: Icons.movie_outlined,
                title: 'Popular Movie',
                showText: showText,
                onTap: () {}
//                     _navigateTo(context, const MoviePage1(), isMobileLayout),
              ),

              _buildNavigationItem(
                context,
                ref,
                icon: Icons.tv_rounded,
                title: 'Popular TV Shows',
                showText: showText,
                onTap: () {}
//                     _navigateTo(context, const TvSearchPage(), isMobileLayout),
              ),

              _buildNavigationItem(
                context,
                ref,
                icon: Icons.search,
                title: 'Search movies',
                showText: showText,
                onTap: (){}
//  _navigateTo(
   //               context,
     //             const MovieSearchPage(),
        //          isMobileLayout,
          //      ),
              ),

              _buildNavigationItem(
                context,
                ref,
                icon: Icons.text_fields,
                title: 'Search keywords',
                showText: showText,
                onTap: () {}
//  _navigateTo(
   //               context,
     //             const KeywordSearchPage(),
       //           isMobileLayout,
         //       ),
              ),

              // _buildNavigationItem(
              //  context,
              //  ref,
              //  icon: Icons.file_copy,
              //  title: 'File Browser',
              //  showText: showText,
              //  onTap: () => _navigateTo(context, const LocalScreen(), isMobileLayout),
              // ),
              _buildNavigationItem(
                context,
                ref,
                icon: Icons.dangerous,
                title: 'Fullscreen',
                showText: showText,
                onTap: () {}
//                    _navigateTo(context, const GridWall(), isMobileLayout),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // New helper methods
  void _navigateTo(BuildContext context, Widget screen, bool isMobileLayout) {
    tVClick();
    if (isMobileLayout) Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required bool showText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: Colors.grey[300]),
              if (showText) ...[
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
