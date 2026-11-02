import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hom_nay_an_gi/app.dart';
import 'package:hom_nay_an_gi/core/providers.dart';
import 'package:hom_nay_an_gi/core/services/local_store.dart';
import 'package:hom_nay_an_gi/features/auth/auth_repository.dart';

// Catalog/GPS integration fixtures do not impersonate a production OAuth session.
// Authentication itself is covered by community_flow_test and community_test.
Future<void> launchCatalogTestApp() async {
  final store = LocalStore(await SharedPreferences.getInstance());
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        initialSettingsProvider.overrideWithValue(store.read()),
        authenticationRequiredProvider.overrideWithValue(false),
      ],
      child: const MealApp(),
    ),
  );
}
