import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Auth ──────────────────────────────────────────────────────────────────
import '../../auth/screens/onboarding_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/signup_screen.dart';
import '../../auth/screens/tutorial_screen.dart';

import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/screens/splash_breathing_screen.dart';
import '../../mood_tracking/screens/moodtracking_screen.dart';
import '../../chatbot/screens/chatbot_screen.dart';
import '../../chatbot/screens/chat_history_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../journal/screens/journal_entry_screen.dart';
import '../../core/models/journal_entry.dart';
import '../../planner/screens/planner_screen.dart';
import '../../self_assessment/screens/assessment_screen.dart';
import '../../self_assessment/screens/burnout_assessment_screen.dart';
import '../../self_assessment/screens/burnout_result_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../crisis/screens/crisis_screen.dart';
import '../../referral/screens/referral_screen.dart';
import '../../breathing/screens/breathing_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../clinical_duty/screens/clinical_duty_screen.dart';

// ── Shell ─────────────────────────────────────────────────────────────────
import '../../shared/widgets/main_shell.dart';
import '../../shared/screens/error_screen.dart';

// ── Auth provider ─────────────────────────────────────────────────────────
import '../../auth/providers/auth_provider.dart';
import '../../core/services/hive_service.dart';
import '../../core/constants/app_constants.dart';

// ── Route Name Constants ──────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String onboarding     = '/onboarding';
  static const String login          = '/login';
  static const String signup         = '/signup';
  static const String tutorial       = '/tutorial';
  static const String splash         = '/splash';
  static const String dashboard      = '/dashboard';
  static const String moodTracking   = '/mood';
  static const String chatbot        = '/chat';
  static const String journal        = '/journal';
  static const String planner        = '/planner';
  static const String selfAssessment = '/assessment';
  static const String burnoutAssessment = '/burnout-assessment';
  static const String burnoutResult = '/burnout-result';
  static const String progress       = '/progress';
  static const String crisis         = '/crisis';
  static const String referral       = '/referral';
  static const String breathing      = '/breathing';
  static const String settings       = '/settings';
  static const String chatHistory    = '/chat-history';
  static const String clinicalDuty   = '/clinical-duty';
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        // ONLY trigger a router refresh if the actual authentication status changes.
        // Ignore minor state ticks like isLoading or error messages.
        final wasAuth = previous?.isAuthenticated ?? false;
        final isAuth = next.isAuthenticated;
        
        if (wasAuth != isAuth) {
          // Wrap in a microtask to ensure we don't trigger a router refresh
          // in the middle of a build frame, which causes assertion crashes.
          Future.microtask(() => notifyListeners());
        }
      },
    );
  }
}

// ── Router Provider ───────────────────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  // Check initial flags for starting location
  final hasSeenOnboarding = HiveService.settingsBox.get(
    AppConstants.keyHasSeenOnboarding,
    defaultValue: false,
  ) as bool;

  // Determine starting location
  String initialLocation = AppRoutes.onboarding;
  if (ref.read(authProvider).isAuthenticated) {
    initialLocation = AppRoutes.dashboard;
  } else if (hasSeenOnboarding) {
    initialLocation = AppRoutes.login;
  }

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: initialLocation,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => HilwayErrorScreen(
      errorMessage: state.error?.message,
    ),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final currentPath = state.matchedLocation;

      // Re-read flag in case it was updated in this session
      final hasSeenOnboardingReactive = HiveService.settingsBox.get(
        AppConstants.keyHasSeenOnboarding,
        defaultValue: false,
      ) as bool;

      final isAuthRoute = [
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.signup,
        AppRoutes.tutorial,
      ].contains(currentPath);

      debugPrint('Router: path=\$currentPath, auth=\$isAuthenticated, seenOnboarding=\$hasSeenOnboardingReactive');

      // ── Access Control ─────────────────────────────────────────────────────

      // 1. Logged In -> Prevent going back to login/signup/onboarding
      if (isAuthenticated && isAuthRoute && currentPath != AppRoutes.tutorial) {
        debugPrint('Router: Authenticated & on AuthRoute -> Dashboard');
        return AppRoutes.dashboard;
      }

      // 2. Not Logged In -> Enforce onboarding or login
      if (!isAuthenticated && !isAuthRoute) {
        debugPrint('Router: Not Auth & High Path -> Guarding...');
        return hasSeenOnboardingReactive ? AppRoutes.login : AppRoutes.onboarding;
      }

      // 3. Prevent Onboarding if already seen
      if (currentPath == AppRoutes.onboarding && hasSeenOnboardingReactive) {
        debugPrint('Router: Onboarding but Seen -> Login/Dashboard');
        return isAuthenticated ? AppRoutes.dashboard : AppRoutes.login;
      }

      return null;
    },
    routes: [
      // ── Auth screens (no bottom nav) ───────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        name: 'tutorial',
        builder: (context, state) => const TutorialScreen(),
      ),

      // ── Main app (wrapped with bottom nav shell) ───────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.moodTracking,
            name: 'moodTracking',
            builder: (context, state) => const MoodTrackingScreen(),
          ),
          GoRoute(
            path: AppRoutes.journal,
            name: 'journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/journal/new',
            name: 'journal-new',
            builder: (context, state) => const JournalEntryScreen(),
          ),
          GoRoute(
            path: '/journal/edit',
            name: 'journal-edit',
            builder: (context, state) {
              final entry = state.extra as JournalEntry?;
              return JournalEntryScreen(entry: entry);
            },
          ),
          GoRoute(
            path: AppRoutes.planner,
            name: 'planner',
            builder: (context, state) => const PlannerScreen(),
          ),
          GoRoute(
            path: AppRoutes.selfAssessment,
            name: 'selfAssessment',
            builder: (context, state) => const SelfAssessmentScreen(),
          ),
          GoRoute(
            path: AppRoutes.burnoutAssessment,
            name: 'burnoutAssessment',
            builder: (context, state) => const BurnoutAssessmentScreen(),
          ),
          GoRoute(
            path: AppRoutes.burnoutResult,
            name: 'burnoutResult',
            builder: (context, state) => const BurnoutResultScreen(),
          ),
          GoRoute(
            path: AppRoutes.progress,
            name: 'progress',
            builder: (context, state) => const ProgressScreen(),
          ),
          GoRoute(
            path: AppRoutes.referral,
            name: 'referral',
            builder: (context, state) => const ReferralScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.clinicalDuty,
            name: 'clinicalDuty',
            builder: (context, state) => const ClinicalDutyScreen(),
          ),
        ],
      ),

      // ── Standalone screens (no bottom nav) ────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashBreathingScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatbot,
        name: 'chatbot',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChatbotScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.chatHistory,
        name: 'chatHistory',
        builder: (context, state) => const ChatHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.crisis,
        name: 'crisis',
        builder: (context, state) => const CrisisScreen(),
      ),
      GoRoute(
        path: AppRoutes.breathing,
        name: 'breathing',
        builder: (context, state) => const BreathingScreen(),
      ),
    ],
  );
});