import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/hive_service.dart';

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

    // Listen for auth state changes (login, logout, token refresh)
    SupabaseService.client.auth.onAuthStateChange.listen((event) {
      state = state.copyWith(
        user: event.session?.user,
        clearUser: event.session == null,
        isLoading: false,
        clearError: true,
      );
    });
  }

  // ── Sign Up ───────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await SupabaseService.instance.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign up failed. Please try again.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please check your connection.',
      );
      return false;
    }
  }

  // ── Sign In ───────────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );
      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in failed. Please try again.',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please check your connection.',
      );
      return false;
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await SupabaseService.instance.signOut();
      // Clear all user data from Hive on sign out
      await HiveService.userCacheBox.clear();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign out failed. Please try again.',
      );
    }
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