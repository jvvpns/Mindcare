import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mindcare/core/constants/app_constants.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static bool get isAuthenticated => currentUser != null;

  Future<void> init() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Auth
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Stream auth state changes
  Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // Generic DB helpers
  Future<List<Map<String, dynamic>>> fetchRows({
    required String table,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
    int? limit,
  }) async {
    var query = client.from(table).select();

    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending) as PostgrestFilterBuilder;
    }

    if (limit != null) {
      query = query.limit(limit) as PostgrestFilterBuilder;
    }

    return await query;
  }

  Future<void> upsertRow({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    await client.from(table).upsert(data);
  }

  Future<void> deleteRow({
    required String table,
    required String id,
  }) async {
    await client.from(table).delete().eq('id', id);
  }

  Future<void> deleteAllUserData() async {
    final userId = currentUserId;
    if (userId == null) return;

    const tables = [
      'mood_logs',
      'stress_ratings',
      'assessments',
      'planner_entries',
      'settings',
    ];

    for (final table in tables) {
      await client.from(table).delete().eq('user_id', userId);
    }

    await signOut();
  }
}