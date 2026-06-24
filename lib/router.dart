part of 'main.dart';

final GoRouter _router = GoRouter(
  initialLocation:
      '/', // This can still be your Splash/Login screen for normal app startups
  routes: [
    // 1. Normal Initial/Splash Screen
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

    // 2. The Telegram Redirect Target
    GoRoute(
      path: '/manga',
      builder: (context, state) {
        // go_router automatically parses query parameters from the redirect URI
        String idToken = state.uri.queryParameters['code'] ?? "";
        ////TODO logic for opening manga page later
        return LibraryScreen();
      },
    ),

    // 3. Main Application Home Screen
    GoRoute(path: '/home', builder: (context, state) => CenterContentPanel(isMobileLayout: true,)),
  ],
);
