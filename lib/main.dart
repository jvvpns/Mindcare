import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_constants.dart';
import 'core/services/hive_service.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Load Env ──────────────────────────────────────────────────────────────
  await dotenv.load(fileName: ".env");

  // ── Hive (adapters + encrypted boxes) ────────────────────────────────────
  await HiveService.init();

  // ── Supabase ──────────────────────────────────────────────────────────────
  await SupabaseService.instance.init();

  // ── Notifications ─────────────────────────────────────────────────────────
  await NotificationService.instance.init();

  runApp(
    const ProviderScope(
      child: HilwayApp(),
    ),
  );
}

class HilwayApp extends ConsumerWidget {
  const HilwayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}