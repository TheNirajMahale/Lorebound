import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
void main() {
  runApp(const ProviderScope(child: LoreboundApp()));
}

class LoreboundApp extends ConsumerWidget {
  const LoreboundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return LoreboundThemeBuilder(
      config: themeConfig,
      builder: (lightTheme, darkTheme) {
        return MaterialApp.router(
          title: 'Lorebound',
          debugShowCheckedModeBanner: false,
          themeMode: themeConfig.mode,
          theme: lightTheme,
          darkTheme: darkTheme,
          routerConfig: router,
        );
      },
    );
  }
}
