import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // Netflix Dark Theme
  static final ThemeData netflixDarkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0), // Use AppColors
    primaryColor: const Color.fromARGB(255, 32, 35, 218), // Netflix Red
    hintColor: Colors.grey[600],
    colorScheme: ColorScheme.dark(
      primary: const Color.fromARGB(255, 113, 41, 206),
      secondary: const Color.fromARGB(220, 199, 15, 206), // Darker Red
      surface: AppColors.secondaryBackground, // Use AppColors
      surfaceContainerHighest: const Color(0xFF2D2D2D),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.grey[300]!,
      onSurfaceVariant: Colors.grey[500]!,
      error: AppColors.accentColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryBackground, // Use AppColors
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.grey[300]),
      titleTextStyle: GoogleFonts.poppins( // Changed font
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
      hintStyle: GoogleFonts.openSans(color: Colors.grey[600]), // Changed font
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Slightly more rounded
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE50914), width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 33, 24, 168),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Slightly more rounded
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.robotoMono( // Changed font
            fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 24, 9, 229),
        textStyle: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold), // Changed font
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.oswald(
          color: Colors.white, fontWeight: FontWeight.bold), // Changed font
      titleLarge: GoogleFonts.lato(
          color: Colors.white, fontWeight: FontWeight.bold), // Changed font
      bodyLarge: GoogleFonts.inter(color: Colors.grey[300]), // Changed font
      bodyMedium: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14), // Added
      bodySmall: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12), // Added
    ),
    cardTheme: CardThemeData( // Changed CardThemeData to CardTheme
      color: AppColors.secondaryBackground, // Use AppColors
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)), // Slightly more rounded
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.primaryBackground,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey[600],
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold), // Added font
      unselectedLabelStyle: GoogleFonts.inter(), // Added font
    ),
    tabBarTheme: TabBarThemeData( // Changed TabBarThemeData to TabBarTheme
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey[600],
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Color(0xFFE50914), width: 3),
      ),
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold), // Added font
      unselectedLabelStyle: GoogleFonts.inter(), // Added font
    ),
  );

  // Netflix Light Theme
  static final ThemeData netflixLightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color.fromARGB(255, 66, 8, 226),
    colorScheme: const ColorScheme.light(
      primary: Color.fromARGB(255, 167, 9, 229),
      secondary: Color.fromARGB(255, 5, 8, 199),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSurface: Color(0xFF333333), // Darker grey for light theme text
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      titleTextStyle: GoogleFonts.poppins(
          color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE50914),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)), // Consistent rounding
        textStyle: GoogleFonts.robotoMono(
            fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.oswald(
          color: Colors.black, fontWeight: FontWeight.bold),
      bodyLarge: GoogleFonts.inter(color: const Color(0xFF333333)), // Darker text
      bodyMedium: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14), // Added
      bodySmall: GoogleFonts.inter(color: Colors.grey[700], fontSize: 12), // Added
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFF5F5F5), // Light card background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
    ),
  );
}

class AppColors {
  static const Color primaryBackground = Color(0xFF0F0F0F); // Very dark grey
  static const Color secondaryBackground =
      Color(0xFF212121); // Slightly lighter grey
  static const Color accentColor = Color(0xFFE50914); // Netflix Red
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Colors.grey;
  static const Color iconColor = Colors.white;
  static const Color chipBackground = Color(0xFF373737);
  static const Color chipBackgroundSelected = Color(0xFFFFFFFF);
  static const Color chipText = Colors.white;
  static const Color chipTextSelected = Colors.black;
  static const Color dividerColor = Colors.grey;
}

class AppColors2 {
  // Primary colors (Deep Purple Palette)
  static const Color primaryColor = Color(0xFF673AB7); // Deep Purple 500
  static const Color primaryVariant = Color(0xFF512DA8); // Deep Purple 700

  // Secondary colors (Teal Accent)
  static const Color secondaryColor = Color(0xFF00BCD4); // Cyan 500
  static const Color secondaryVariant = Color(0xFF0097A7); // Cyan 700

  // Text Colors
  static const Color primaryText = Colors.white; // For dark backgrounds
  static const Color secondaryText = Color(0xFFBDBDBD); // Light grey for subtle text
  static const Color tertiaryText = Color(0xFF9E9E9E); // Even lighter grey for tiny text

  // Background colors
  static const Color blackbackground = Color(0xFF000000); // Pure black
  static const Color whitebackground = Color(0xFFF8F8F8); // Very light grey

  // Surface and Card colors
  static const Color surfaceLight = Colors.white; // For light theme surfaces
  static const Color surfaceDark = Color(0xFF1F1F1F); // For dark theme surfaces
  static const Color cardLight = Color(0xFFFFFFFF); // For light theme cards
  static const Color cardDark = Color(0xFF2D2D2D); // For dark theme cards

  // Shimmer effect colors
  static const Color shimmerBase = Color(0xFF3A3A3A);
  static const Color shimmerHighlight = Color(0xFF4C4C4C);

  // Error color
  static const Color error = Color(0xFFD32F2F); // Standard Material Red

  // Additional custom colors (kept original values, could be refined based on new palette)
  static const Color error2 = Color.fromARGB(255, 255, 123, 0);
  static const Color error3 = Color.fromARGB(255, 200, 210, 0);
  static const Color extracolor = Color.fromARGB(255, 35, 252, 2);
  static const Color extracolor2 = Color.fromARGB(255, 0, 21, 255);
  static const Color extracolor3 = Color.fromARGB(255, 111, 189, 1);
  static const Color extracolor4 = Color.fromARGB(255, 82, 3, 90);
  static const Color extracolor5 = Color.fromARGB(255, 128, 233, 243);
  static const Color extracolor6 = Color.fromARGB(255, 106, 2, 2);
  static const Color extracolor7 = Color.fromARGB(255, 31, 8, 133);
  static const Color extracolor8 = Color.fromARGB(255, 7, 227, 143);
  static const Color extracolor9 = Color.fromARGB(87, 184, 42, 158);

  static const Color primaryBackgroundDark = Color(0xFF121212); // Dark background

  static const Color accentColor = Color(0xFFFF4081); // A vibrant accent (Pink)
  static const Color accentColorLight =
      Color(0xFFEA80FC); // Lighter accent variant (Purple A100)

  // On colors (for text/icons on top of specific backgrounds)
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.black;
  static const Color onBackgroundLight = Colors.black;
  static const Color onBackgroundDark = Colors.white;
  static const Color onSurfaceLight = Colors.black;
  static const Color onSurfaceDark = Colors.white;
  static const Color onError = Colors.white;

  static const Color tinytext = Color.fromARGB(221, 191, 188, 188); // Keeping original for compatibility
  static const Color favoriteActive = Colors.pinkAccent;
  static const Color watchlistActive =
      Color(0xFF69F0AE); // Brighter green (Green Accent A200)

  // Divider colors
  static const Color dividerLight = Color(0xFFE0E0E0); // Light grey
  static const Color dividerDark = Color(0xFF424242); // Dark grey

  // Gradient colors (adjusted to new palette)
  static const List<Color> primaryGradient = [
    Color(0xFF673AB7), // Deep Purple 500
    Color(0xFF9C27B0), // Purple 500
    Color.fromARGB(255, 76, 2, 255), // A more vibrant blue-purple
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFF00BCD4), // Cyan 500
    Color(0xFF0097A7), // Cyan 700
    Color.fromARGB(255, 14, 2, 255), // A deep blue
  ];
}

// Theme configuration for the app
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors2.primaryColor,
      colorScheme: ColorScheme(
        primary: AppColors2.primaryColor,
        primaryContainer: AppColors2.primaryVariant,
        secondary: AppColors2.secondaryColor,
        secondaryContainer: AppColors2.secondaryVariant,
        surface: AppColors2.surfaceLight,
        error: AppColors2.error,
        onPrimary: AppColors2.onPrimary,
        onSecondary: AppColors2.onSecondary,
        onSurface: AppColors2.onSurfaceLight,
        onError: AppColors2.onError,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors2.whitebackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors2.primaryColor,
        foregroundColor: AppColors2.onPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.montserrat(
            color: AppColors2.onPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: AppColors2.cardLight,
        elevation: 4, // Increased elevation for light theme
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // More rounded corners
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors2.primaryColor,
          foregroundColor: AppColors2.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Consistent rounding
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.lato(
              fontSize: 16, fontWeight: FontWeight.bold), // Applied Google Font
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors2.primaryColor,
          textStyle: GoogleFonts.lato(
              fontWeight: FontWeight.bold), // Applied Google Font
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors2.primaryColor,
          side: BorderSide(color: AppColors2.primaryColor, width: 1.5), // Thicker border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Consistent rounding
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.lato(
              fontWeight: FontWeight.bold), // Applied Google Font
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), // Consistent rounding
          borderSide: BorderSide.none, // Default to no border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors2.primaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder( // Added enabled border
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
        filled: true,
        fillColor: AppColors2.surfaceLight,
        hintStyle: GoogleFonts.inter(
            color: AppColors2.tertiaryText, fontSize: 14), // Applied Google Font
        labelStyle: GoogleFonts.inter(
            color: AppColors2.primaryColor, fontSize: 14), // Applied Google Font
      ),
      dividerTheme: DividerThemeData(
        color: AppColors2.dividerLight,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          height: 1.2,
          shadows: [
            Shadow(
              offset: Offset(2, 2),
              blurRadius: 8,
              color: Colors.black.withValues(alpha:0.6), // Slightly less opaque
            ),
            Shadow(
              offset: Offset(-1, -1),
              blurRadius: 4,
              color: AppColors2.primaryColor.withValues(alpha:0.3), // Use primary color
            ),
            Shadow(
              offset: Offset(0, 0),
              blurRadius: 20,
              color: AppColors2.secondaryColor.withValues(alpha:0.4), // Use secondary color
            ),
          ],
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [
                const Color(0xFFFF6B6B), // Vivid Red
                const Color(0xFF4ECDC4), // Soft Green
                const Color(0xFF45B7D1), // Sky Blue
                const Color(0xFF96CEB4), // Pastel Green
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, 300, 100)),
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors2.onBackgroundLight,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors2.onBackgroundLight,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors2.onBackgroundLight,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors2.onBackgroundLight,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors2.onBackgroundLight,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors2.onBackgroundLight,
        ),
        bodySmall: GoogleFonts.inter( // Added new text style
          fontSize: 12,
          color: AppColors2.tertiaryText,
        ),
        labelLarge: GoogleFonts.lato( // Added label text style
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors2.primaryColor,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors2.primaryColor,
      colorScheme: ColorScheme(
        primary: AppColors2.primaryColor,
        primaryContainer: AppColors2.primaryVariant,
        secondary: AppColors2.secondaryColor,
        secondaryContainer: AppColors2.secondaryVariant,
        surface: AppColors2.surfaceDark,
        error: AppColors2.error,
        onPrimary: AppColors2.onPrimary,
        onSecondary: AppColors2.onSecondary,
        onSurface: AppColors2.onSurfaceDark,
        onError: AppColors2.onError,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors2.primaryBackgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors2.surfaceDark,
        foregroundColor: AppColors2.onBackgroundDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.montserrat(
            color: AppColors2.onBackgroundDark,
            fontSize: 20,
            fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: AppColors2.cardDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors2.primaryColor,
          foregroundColor: AppColors2.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.lato(
              fontSize: 16, fontWeight: FontWeight.bold), // Applied Google Font
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors2.secondaryColor,
          textStyle: GoogleFonts.lato(
              fontWeight: FontWeight.bold), // Applied Google Font
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors2.secondaryColor,
          side: BorderSide(color: AppColors2.secondaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.lato(
              fontWeight: FontWeight.bold), // Applied Google Font
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors2.secondaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder( // Added enabled border
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!, width: 1),
        ),
        filled: true,
        fillColor: const Color(0xFF2C2C2C), // Darker fill color for input
        hintStyle: GoogleFonts.inter(
            color: AppColors2.tertiaryText, fontSize: 14), // Applied Google Font
        labelStyle: GoogleFonts.inter(
            color: AppColors2.secondaryColor, fontSize: 14), // Applied Google Font
      ),
      dividerTheme: DividerThemeData(
        color: AppColors2.dividerDark,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors2.onBackgroundDark,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors2.onBackgroundDark,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors2.onBackgroundDark,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors2.onBackgroundDark,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors2.onBackgroundDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors2.onBackgroundDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors2.onBackgroundDark,
        ),
        bodySmall: GoogleFonts.inter( // Added new text style
          fontSize: 12,
          color: AppColors2.tertiaryText,
        ),
        labelLarge: GoogleFonts.lato( // Added label text style
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors2.secondaryColor,
        ),
      ),
    );
  }
}
// Example of how to use the MaterialApp with the theme
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Awesome App',
//       theme: AppTheme.lightTheme,
//       darkTheme: AppTheme.darkTheme,
//       themeMode: ThemeMode.system, // Follows system theme
//       debugShowCheckedModeBanner: false,
//       home: const HomePagetest(),
//     );
//   }
// }

// // Placeholder for HomePage
// class HomePagetest extends StatelessWidget {
//   const HomePagetest({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Awesome App'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Welcome to Awesome App!',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {},
//               child: const Text('Primary Button'),
//             ),
//             const SizedBox(height: 12),
//             OutlinedButton(
//               onPressed: () {},
//               child: const Text('Outlined Button'),
//             ),
//             const SizedBox(height: 12),
//             TextButton(
//               onPressed: () {},
//               child: const Text('Text Button'),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {},
//         backgroundColor: AppColors2.secondaryColor,
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }