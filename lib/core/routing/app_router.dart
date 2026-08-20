import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_scaffold.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/book_detail_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/library',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _libraryNavigatorKey,
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: 'book/:id',
                    builder: (context, state) {
                      final idStr = state.pathParameters['id']!;
                      return BookDetailScreen(bookId: int.parse(idStr));
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsNavigatorKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Reader is full-screen and outside the MainScaffold
      GoRoute(
        path: '/reader',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final filePath = state.uri.queryParameters['filePath'];
          final bookIdStr = state.uri.queryParameters['bookId'];
          final initialChapterStr = state.uri.queryParameters['chapter'];
          
          if (filePath == null || bookIdStr == null) {
            return const Scaffold(body: Center(child: Text('Invalid reader arguments')));
          }
          
          final bookId = int.tryParse(bookIdStr) ?? -1;
          final initialChapter = initialChapterStr != null ? int.tryParse(initialChapterStr) : null;
          
          return ReaderScreen(
            bookId: bookId,
            filePath: filePath,
            initialChapter: initialChapter,
          );
        },
      ),
    ],
  );
});
