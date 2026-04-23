import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../providers/journal_provider.dart';
import '../../shared/widgets/hilway_background.dart';
import '../../shared/widgets/hilway_glass.dart';
import '../../shared/widgets/hilway_card.dart';
import '../../chatbot/providers/kelly_state_provider.dart';
import '../../shared/widgets/responsive_wrapper.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Premium bottom-sheet delete confirmation ──────────────────────────
  Future<bool> _confirmDelete(BuildContext context, String entryTitle) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.crisis.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.crisis,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Delete Entry?', style: AppTextStyles.headingSmall),
            const SizedBox(height: 8),
            Text(
              '"$entryTitle" will be permanently removed.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.crisis,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Yes, Delete',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Keep It',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  void _deleteEntry(BuildContext context, WidgetRef ref, String id) {
    ref.read(journalProvider.notifier).deleteEntry(id);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(journalProvider);

    // ── Search Filtering ───────────────────────────────────────────────────
    final filteredEntries = entries.where((e) {
      final query = _searchQuery.toLowerCase();
      return e.title.toLowerCase().contains(query) ||
          e.content.toLowerCase().contains(query);
    }).toList();

    final effectiveEmotion = ref.watch(globalBackgroundEmotionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HilwayBackground(
        emotion: effectiveEmotion,
        child: ResponsiveWrapper(
          child: Stack(
            children: [
              // ── Scrollable Journal List ──────────────────────────────────────────
              SafeArea(
                child: filteredEntries.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 140, 24, 40),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          final formattedDate = DateFormat(
                            'MMM d, yyyy • h:mm a',
                          ).format(entry.createdAt);

                          // ── Mood Color Logic ─────────────────────────────────
                          Color glowColor = AppColors.primary;
                          if (entry.moodIndex != null) {
                            final mIndex = entry.moodIndex!.toInt();
                            switch (mIndex) {
                              case 0:
                                glowColor = AppColors.crisis;
                                break; // Sad
                              case 1:
                                glowColor = AppColors.moodConcerned;
                                break;
                              case 2:
                                glowColor = AppColors.textSecondary;
                                break; // Neutral
                              case 3:
                                glowColor = AppColors.moodHappy;
                                break; // Calm/Sky
                              case 4:
                                glowColor = AppColors.warning;
                                break; // Motivated
                            }
                          }

                          return Dismissible(
                            key: Key(entry.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) =>
                                _confirmDelete(context, entry.title),
                            onDismissed: (_) {
                              HapticFeedback.heavyImpact();
                              _deleteEntry(context, ref, entry.id);
                            },
                            background: _buildDeleteBackground(),
                            child: GestureDetector(
                              onTap: () =>
                                  context.push('/journal/edit', extra: entry),
                              child: HilwayCard(
                                isGlass: true,
                                glowColor: glowColor.withValues(alpha: 0.25),
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formattedDate,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.textTertiary,
                                              ),
                                        ),
                                        if (entry.moodIndex != null &&
                                            entry.moodIndex! >= 0 &&
                                            entry.moodIndex! <
                                                AppConstants
                                                    .moodAnimatedAssets
                                                    .length)
                                          Image.asset(
                                            AppConstants
                                                .moodAnimatedAssets[entry
                                                .moodIndex!
                                                .toInt()],
                                            width: 30,
                                            height: 30,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      entry.title,
                                      style: AppTextStyles.labelLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.content,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // ── Premium Glass Header & Search ────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HilwayGlass(
                  sigmaX: 12,
                  sigmaY: 12,
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.1),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      bottom: 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            children: [
                              const Text(
                                'Journal Journey',
                                style: AppTextStyles.headingSmall,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const PhosphorIcon(
                                  PhosphorIconsRegular.pencilSimpleLine,
                                ),
                                onPressed: () {
                                  HapticFeedback.mediumImpact();
                                  context.push('/journal/new');
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  foregroundColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ── Search Bar ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: HilwayCard(
                            isGlass: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 0,
                            ),
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: AppTextStyles.bodyMedium,
                              decoration: InputDecoration(
                                hintText: 'Search reflections...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                                border: InputBorder.none,
                                icon: const PhosphorIcon(
                                  PhosphorIconsRegular.magnifyingGlass,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.crisis.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: const Icon(
        Icons.delete_rounded,
        color: AppColors.crisis,
        size: 28,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const PhosphorIcon(
              PhosphorIconsRegular.bookOpenText,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          const Text('No reflections found', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start your journey by writing your first thought.'
                : 'Try a different search term.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
