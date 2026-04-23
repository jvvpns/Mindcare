import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hilway/core/constants/app_constants.dart';
import 'package:hilway/core/services/supabase_service.dart';
import 'package:hilway/core/models/sync_job.dart';
import 'package:hilway/core/models/mood_log.dart';
import 'package:hilway/core/models/stress_rating.dart';
import 'package:hilway/core/models/planner_entry.dart';
import 'package:hilway/core/models/journal_entry.dart';
import 'package:hilway/clinical_duty/models/shift_task.dart';
import 'package:hilway/core/services/hive_service.dart';

/// Senior-grade SyncService with State Machine and Exponential Backoff.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  bool _isProcessing = false;
  Timer? _retryTimer;

  Box<SyncJob> get _queueBox => Hive.box<SyncJob>(AppConstants.boxSyncQueue);

  /// Initializes the sync service and recovers from any crashes.
  Future<void> init() async {
    await _recoverInterruptedJobs();
    processQueue(); // Start background sync
  }

  /// Resets any jobs stuck in 'syncing' state back to 'pending'.
  /// This handles scenarios where the app was closed mid-sync.
  Future<void> _recoverInterruptedJobs() async {
    final interrupted = _queueBox.values.where((job) => job.state == SyncState.syncing).toList();
    for (final job in interrupted) {
      job.state = SyncState.pending;
      await job.save();
    }
    if (interrupted.isNotEmpty) {
      debugPrint('SyncService: Recovered ${interrupted.length} interrupted jobs.');
    }
  }

  /// Queues an upsert action.
  Future<void> queueUpsert({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    data['user_id'] = userId;
    
    // Use the model's timestamp as an idempotency/version key
    // Most models use 'logged_at', 'created_at', or 'taken_at'
    final timestamp = data['logged_at'] ?? data['created_at'] ?? data['taken_at'] ?? DateTime.now().toIso8601String();

    final job = SyncJob(
      id: '${table}_$id',
      action: 'upsert',
      table: table,
      payload: data,
    );

    // Durable persistence to IndexedDB
    await _queueBox.put(job.id, job);
    debugPrint('SyncService: Queued ${job.id} (v: $timestamp)');

    processQueue();
  }

  /// Queues a delete action.
  Future<void> queueDelete({
    required String table,
    required String id,
  }) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    final job = SyncJob(
      id: 'del_${table}_$id',
      action: 'delete',
      table: table,
      payload: {'id': id, 'user_id': userId},
    );

    await _queueBox.put(job.id, job);
    debugPrint('SyncService: Queued delete for ${job.id}');

    processQueue();
  }

  /// Processes the queue with a state machine and batching optimization.
  Future<void> processQueue() async {
    if (_isProcessing || _queueBox.isEmpty) return;
    
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    _isProcessing = true;
    _retryTimer?.cancel();

    try {
      final jobs = _queueBox.values
          .where((j) => j.state == SyncState.pending || j.state == SyncState.retrying)
          .toList();

      if (jobs.isEmpty) return;

      // Sort by creation time to preserve causal order
      jobs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Separate Batchable Upserts from individual Deletes
      final upsertGroups = <String, List<SyncJob>>{};
      final individualJobs = <SyncJob>[];

      for (final job in jobs) {
        // Check backoff if retrying
        if (job.state == SyncState.retrying && !_shouldRetry(job)) continue;

        if (job.action == 'upsert') {
          upsertGroups.putIfAbsent(job.table, () => []).add(job);
        } else {
          individualJobs.add(job);
        }
      }

      // 1. Process Batch Upserts (High Efficiency)
      for (final table in upsertGroups.keys) {
        await _syncBatch(table, upsertGroups[table]!);
      }

      // 2. Process Individual Actions (e.g., Deletes)
      for (final job in individualJobs) {
        await _syncJob(job);
      }
      
    } finally {
      _isProcessing = false;
      
      if (_queueBox.isNotEmpty) {
        _retryTimer = Timer(const Duration(seconds: 30), processQueue);
      }
    }
  }

  Future<void> _syncBatch(String table, List<SyncJob> jobs) async {
    if (jobs.isEmpty) return;

    // Mark all as syncing
    for (final job in jobs) {
      job.state = SyncState.syncing;
      job.lastAttempt = DateTime.now();
      await job.save();
    }

    try {
      // Extract payloads
      final payloads = jobs.map((j) => j.payload).toList();

      await SupabaseService.client
          .from(table)
          .upsert(payloads)
          .timeout(const Duration(seconds: 30));

      // Success: Remove all from queue
      for (final job in jobs) {
        await _queueBox.delete(job.id);
      }
      debugPrint('SyncService: Successfully batched ${jobs.length} items to $table');

    } catch (e) {
      // Failure: Revert to retrying state individually
      for (final job in jobs) {
        if (e is PostgrestException && (e.code?.startsWith('22') ?? false)) {
          job.state = SyncState.failed;
        } else {
          job.state = SyncState.retrying;
          job.retryCount++;
        }
        await job.save();
      }
      debugPrint('SyncService: Batch failed for $table: $e');
    }
  }

  bool _shouldRetry(SyncJob job) {
    if (job.lastAttempt == null) return true;
    
    // Exponential backoff: 2^retryCount * 2 seconds
    final delay = pow(2, job.retryCount) * 2000; 
    final nextAllowed = job.lastAttempt!.add(Duration(milliseconds: delay.toInt()));
    
    return DateTime.now().isAfter(nextAllowed);
  }

  Future<void> _syncJob(SyncJob job) async {
    if (!job.isInBox) return;

    job.state = SyncState.syncing;
    job.lastAttempt = DateTime.now();
    await job.save();

    try {
      if (job.action == 'delete') {
        await SupabaseService.client
            .from(job.table)
            .delete()
            .eq('id', job.payload['id'])
            .timeout(const Duration(seconds: 15));
      }

      await _queueBox.delete(job.id);
      debugPrint('SyncService: Successfully synced individual job ${job.id}');
      
    } catch (e) {
      if (e is PostgrestException && (e.code?.startsWith('22') ?? false)) {
        job.state = SyncState.failed;
      } else {
        job.state = SyncState.retrying;
        job.retryCount++;
      }
      await job.save();
    }
  }

  /// Pulls all user data from Supabase (Recovery/Sync).
  Future<void> pullAllData() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      debugPrint('SyncService: Starting global data pull...');
      
      // 1. Pull & Save Mood Logs
      final moods = await SupabaseService.client.from('mood_logs').select().eq('user_id', userId);
      for (var json in moods) {
        final log = MoodLog.fromMap(json);
        await HiveService.moodBox.put(log.id, log);
      }
      
      // 2. Pull & Save Stress Ratings
      final stress = await SupabaseService.client.from('stress_ratings').select().eq('user_id', userId);
      for (var json in stress) {
        final log = StressRating.fromMap(json);
        await HiveService.stressBox.put(log.id, log);
      }

      // 3. Pull & Save Planner Entries
      final planner = await SupabaseService.client.from('planner_entries').select().eq('user_id', userId);
      for (var json in planner) {
        final entry = PlannerEntry.fromMap(json);
        await HiveService.plannerBox.put(entry.id, entry);
      }

      // 4. Pull & Save Journal Entries
      final journals = await SupabaseService.client.from('journal_entries').select().eq('user_id', userId);
      for (var json in journals) {
        final entry = JournalEntry.fromMap(json);
        await HiveService.journalBox.put(entry.id, entry);
      }
      
      // 5. Pull & Save Shift Tasks (Clinical Duties)
      final shifts = await SupabaseService.client.from('shift_tasks').select().eq('user_id', userId);
      for (var json in shifts) {
        final task = ShiftTask.fromMap(json);
        await HiveService.shiftBox.put(task.id, task);
      }
      
      debugPrint('SyncService: Successfully pulled ${moods.length} moods, ${planner.length} tasks, ${shifts.length} shift duties.');
    } catch (e) {
      debugPrint('SyncService: Global pull failed: $e');
    }
  }
}
