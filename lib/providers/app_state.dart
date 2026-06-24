import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:omiku/main.dart';
import 'package:omiku/services/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
final container = ProviderContainer();
final settingsService = container.read(settingsServiceProvider);
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  debugPrint('Initializing SharedPreferences');
  return await SharedPreferences.getInstance();
});
final setsettingsService = settingsServiceProvider.overrideWith(
  (ref) => settingsService);

//final settingsServiceProvider = ChangeNotifierProvider<DatabaseService>((ref) {
//  return DatabaseService();
//});

final settingsServiceProvider = ChangeNotifierProvider<DatabaseService>((ref) {
  return db;
});

final rightSidebarCollapsedProvider = StateProvider<bool>((ref) => true);
final sidebarCollapsedProvider = StateProvider<bool>((ref) => true);

