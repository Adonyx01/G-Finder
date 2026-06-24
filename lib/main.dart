import 'package:flutter/material.dart';

import 'core/app_router.dart';
import 'core/backend_mode.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (BackendMode.useSupabase) {
    await SupabaseConfig.initialize();
  }
  runApp(const ChezMoiApp());
}

class ChezMoiApp extends StatelessWidget {
  const ChezMoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChezMoi',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: createAppRouter(),
    );
  }
}
