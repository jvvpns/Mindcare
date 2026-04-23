import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/sync_service.dart';

// ── Auth State Model ──────────────────────────────────────────────────────
class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) =>
      AuthState(
        user: clearUser ? null : user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      );
}

// ── Auth Notifier ─────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    // Set initial user from current session
    final currentUser = SupabaseService.currentUser;
    state = AuthState(user: currentUser);

    // If user is already logged in (e.g., returning to PWA), trigger a background sync
    // to ensure data from other devices (like localhost) is pulled down.
    if (currentUser != null) {
      debugPrint('AuthNotifier: User already logged in. Triggering background pullAllData...');
      SyncService.instance.pullAllData().catchError((e) {
        debugPrint('AuthNotifier: Background sync error: $e');
      });
    }

    // Listen for auth state changes (login, logout, token refresh)
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      // Only clear error and update state if it's a meaningful change
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        state = state.copyWith(
          user: session?.user,
          clearUser: session == null,
          isLoading: false,
          clearError: event == AuthChangeEvent.signedIn, // Clear error on success
        );
      } else {
        // Just update user for refresh
        state = state.copyWith(
          user: session?.user,
          clearUser: session == null,
          isLoading: false,
        );
      }
    });
  }

  // ── Sign Up ───────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String yearLevel,
    required String school,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('AuthNotifier: Starting signUp for $email...');
      debugPrint('AuthNotifier: URL: ${AppConstants.supabaseUrl}');
      debugPrint('AuthNotifier: KEY: ${AppConstants.supabaseAnonKey.substring(0, 15)}...');
      
      final response = await SupabaseService.instance.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'year_level': yearLevel,
          'school': school,
        },
      );
      
      debugPrint('AuthNotifier: Supabase signUp response received. User: ${response.user?.id}');

      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isLoading: false,
        );
        debugPrint('AuthNotifier: SignUp successful, state updated.');
        return true;
      }
      debugPrint('AuthNotifier: SignUp failed - no user in response');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign up failed. Please try again.',
      );
      return false;
    } on AuthException catch (e) {
      debugPrint('AuthNotifier: AuthException during signUp: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyAuthError(e.message),
      );
      return false;
    } catch (e) {
      debugPrint('AuthNotifier: Unexpected error during signUp: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please check your connection.',
      );
      return false;
    } finally {
      // Ensure loading is false even if everything above fails
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      debugPrint('AuthNotifier: Starting signIn for $email...');
      debugPrint('AuthNotifier: URL: ${AppConstants.supabaseUrl}');
      debugPrint('AuthNotifier: KEY: ${AppConstants.supabaseAnonKey.substring(0, 15)}...');
      
      final response = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );
      
      debugPrint('AuthNotifier: Supabase signIn response received. User: ${response.user?.id}');

      if (response.user != null) {
        // Pull all offline data from cloud into Hive with a timeout to prevent hanging
        debugPrint('AuthNotifier: Pulling remote data...');
        try {
          await SyncService.instance.pullAllData().timeout(
            const Duration(seconds: 10),
            onTimeout: () => debugPrint('AuthNotifier: Sync pullAllData timed out, continuing...'),
          );
        } catch (e) {
          debugPrint('AuthNotifier: Sync pullAllData error: $e');
        }

        state = state.copyWith(
          user: response.user,
          isLoading: false,
        );
        debugPrint('AuthNotifier: SignIn successful, state updated.');
        return true;
      }
      debugPrint('AuthNotifier: SignIn failed - no user in response');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in failed. Please try again.',
      );
      return false;
    } on AuthException catch (e) {
      final friendlyError = _friendlyAuthError(e.message);
      debugPrint('AuthNotifier: AuthException during signIn: $friendlyError');
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyError,
      );
      return false;
    } catch (e) {
      debugPrint('AuthNotifier: Unexpected error during signIn: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please check your connection.',
      );
      return false;
    } finally {
      // Ensure loading is false even if everything above fails
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────
  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await SupabaseService.instance.signOut();
      // Securely wipe ALL local user data from Hive on sign out
      await HiveService.clearAllData();
      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign out failed. Please try again.',
      );
      return false;
    }
  }

  // ── Skip/Bypass Auth (Development Only) ─────────────────────────────
  Future<void> skipAuth() async {
    state = state.copyWith(isLoading: true);
    // Artificial delay to mimic network
    await Future.delayed(const Duration(milliseconds: 500));
    
    // We create a dummy User object. 
    // Since we can't easily instantiate a real Supabase User object manually, 
    // we'll just set a mock state.
    state = AuthState(
      user: User(
        id: 'dummy-user-id',
        appMetadata: {},
        userMetadata: {'first_name': 'Guest', 'school': 'Hilway Demo'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'guest@hilway.com',
      ),
      isLoading: false,
    );
    debugPrint('AuthNotifier: Auth bypassed with dummy user.');
  }

  // ── Clear Error ───────────────────────────────────────────────────────
  void clearError() => state = state.copyWith(clearError: true);

  // ── Friendly Error Messages ───────────────────────────────────────────
  String _friendlyAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email already')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('password')) {
      return 'Password must be at least 8 characters.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'No internet connection. Please check your network.';
    }
    if (lower.contains('apikey') || lower.contains('api key') || lower.contains('unauthorized')) {
      return 'Supabase configuration error. Please check your Anon Key in .env';
    }
    return message;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Convenience provider — just the auth state
final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authProvider);
});

// Convenience provider — is user logged in
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});