import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_scaffold.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/library/presentation/screens/book_detail_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/more/presentation/screens/more_screen.dart';
import '../../features/more/presentation/screens/category_management_screen.dart';
import '../../features/more/presentation/screens/downloads_screen.dart';
import '../../features/more/presentation/screens/statistics_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/appearance_settings_screen.dart';
import '../../features/settings/presentation/screens/library_settings_screen.dart';
import '../../features/settings/presentation/screens/reader_settings_screen.dart';
import '../../features/settings/presentation/screens/data_storage_settings_screen.dart';
import '../../features/reader/presentation/screens/reader_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _libraryNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'library');
final _historyNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'history');
final _moreNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'more');

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
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _historyNavigatorKey,
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _moreNavigatorKey,
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Sub-pages: full-screen (no bottom nav bar) ---
      // They use _rootNavigatorKey so they push on top of MainScaffold.

      // Library sub-pages
      GoRoute(
        path: '/library/book/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final idStr = state.pathParameters['id']!;
          return BookDetailScreen(bookId: int.parse(idStr));
        },
      ),

      // More sub-pages
      GoRoute(
        path: '/more/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/more/downloads',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DownloadsScreen(),
      ),
      GoRoute(
        path: '/more/statistics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/more/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Settings sub-pages
      GoRoute(
        path: '/more/settings/appearance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AppearanceSettingsScreen(),
      ),
      GoRoute(
        path: '/more/settings/library',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LibrarySettingsScreen(),
      ),
      GoRoute(
        path: '/more/settings/reader',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReaderSettingsScreen(),
      ),
      GoRoute(
        path: '/more/settings/data-storage',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DataStorageSettingsScreen(),
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
