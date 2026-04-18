import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/hilway_card.dart';
import '../../mood_tracking/providers/mood_provider.dart';
import '../../mood_tracking/widgets/mood_bottom_sheet.dart';
import '../../journal/providers/journal_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/wellness_gauge.dart';
import '../providers/pulse_provider.dart';
import '../providers/streak_provider.dart';
import '../../shared/widgets/hilway_background.dart';
import '../../planner/providers/planner_provider.dart';
import '../../chatbot/widgets/kelly_orb_mascot.dart';
import '../../chatbot/providers/kelly_state_provider.dart';
import '../providers/dashboard_interaction_provider.dart';
import '../../core/models/mood_log.dart';
import '../../core/providers/health_provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final userName = user?.email?.split('@').first ?? 'Guiding Star';
    final dailyQuote = ref.watch(dailyQuoteProvider);
    final kellyEmotion = ref.watch(kellyEmotionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HilwayBackground(
        child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeader(context, userName, dailyQuote, ref, kellyEmotion),
                  const SizedBox(height: 32),
                  
                  _buildMoodCheckerRow(context, ref),
                  const SizedBox(height: 24),

                  _buildHeroJournalCard(context, ref),
                  const SizedBox(height: 24),
                  
                  _buildNextTaskCard(context, ref),

                  _buildToolGrid(context, ref),
                  const SizedBox(height: 48), // Bottom padding
                ]),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ── Greeting helper ────────────────────────────────────────────────────
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _getMoodAnalysis(MoodLog? log, String fallbackQuote, double sleepHours) {
    // ── Priority 1: Low Sleep Insight ──────────────────────────────────────
    if (sleepHours > 0 && sleepHours < 6) {
      return "I see you only had ${sleepHours.toStringAsFixed(1)} hours of sleep. Please take it easy today, and remember to rest when you can.";
    }

    // ── Priority 2: Deep Mood & Note Analysis ──────────────────────────────
    if (log == null) return fallbackQuote;
    
    final mood = log.moodLabel.toLowerCase();
    final note = log.note?.toLowerCase() ?? '';

    // Smart Keyword Analysis (Offline Intelligence)
    if (note.contains('exam') || note.contains('quiz') || note.contains('study')) {
      return "I see you're focusing on your studies. Don't let the exam stress get to you—you're doing great!";
    }
    if (note.contains('duty') || note.contains('hospital') || note.contains('patient')) {
      return "Hospital duties can be draining. Your compassion is making a real difference today.";
    }
    if (note.contains('tired') || note.contains('sleepy') || note.contains('exhausted')) {
      return "You seem really exhausted. Please prioritize some rest after your shift!";
    }

    // Fallback to General Mood Analysis
    switch (mood) {
      case 'calm':
        return "You're feeling calm today. It's a great time to focus on your studies.";
      case 'happy':
        return "I love seeing you happy! Keep that positive energy going throughout your shift.";
      case 'energetic':
        return "You've got a lot of energy today! Maybe tackle those complex clinical charts now?";
      case 'anxious':
        return "Feeling a bit anxious? Remember to take slow breaths. You've got this.";
      case 'sad':
        return "It's okay to feel sad. Take things one step at a time today. I'm here if you want to chat.";
      case 'depressed':
        return "You seem really down. Please be gentle with yourself today. I'm always here for you.";
      default:
        return fallbackQuote;
    }
  }

  Widget _buildHeader(BuildContext context, String name, String quote, WidgetRef ref, String kellyEmotion) {
    final todayMood = ref.watch(todayMoodProvider);
    final sleepHours = ref.watch(sleepDurationProvider);
    final pokedMessage = ref.watch(kellyPokedMessageProvider);
    
    // pokedMessage takes priority if it's active
    final message = pokedMessage ?? _getMoodAnalysis(todayMood, quote, sleepHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _greeting(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _capitalize(name),
                    style: AppTextStyles.displayMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                // ── Gamification: Daily Streak ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const PhosphorIcon(PhosphorIconsFill.plant, color: AppColors.success, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${ref.watch(streakProvider)}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ── Notification Bell ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const PhosphorIcon(
                    PhosphorIconsRegular.bell,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // ── Speaking Mascot Component ──────────────────────────────────────
        GestureDetector(
          onTap: () => ref.read(kellyPokedMessageProvider.notifier).poke(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kelly Mini Orb (The Avatar)
              SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: KellyMiniOrb(emotion: kellyEmotion, size: 48),
                ),
              ),
              const SizedBox(width: 12),
              // Speech Bubble
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Kelly",
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.auto_awesome, size: 12, color: AppColors.primary.withValues(alpha: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodCheckerRow(BuildContext context, WidgetRef ref) {
    final todayLog = ref.watch(todayMoodProvider);

    return HilwayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            todayLog == null ? "How are you feeling today?" : "You're feeling ${todayLog.moodLabel}",
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(AppConstants.moodEmojis.length, (index) {
                final isSelected = todayLog != null && todayLog.moodIndex == index;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      if (todayLog == null) {
                        MoodBottomSheet.show(context, index);
                      }
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              AppConstants.moodAnimatedAssets[index],
                              width: 36,
                              height: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.moodLabels[index],
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroJournalCard(BuildContext context, WidgetRef ref) {
    final journals = ref.watch(journalProvider);
    final hasLogs = journals.isNotEmpty;
    final snippet = hasLogs ? journals.first.content : "Write down one good thing that happened today.";

    return HilwayCard(
      color: AppColors.secondary.withValues(alpha: 0.12),
      onTap: () => context.push(AppRoutes.journal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const PhosphorIcon(PhosphorIconsRegular.bookOpenText, color: AppColors.secondary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text("Daily Reflection", style: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary)),
                ],
              ),
              PhosphorIcon(PhosphorIconsRegular.caretRight, color: AppColors.secondary.withValues(alpha: 0.6), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            snippet,
            style: AppTextStyles.bodyMedium.copyWith(
              color: hasLogs ? AppColors.textPrimary : AppColors.textSecondary,
              fontStyle: hasLogs ? FontStyle.normal : FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNextTaskCard(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(plannerProvider);
    final now = DateTime.now();
    final next24Hours = now.add(const Duration(hours: 24));
    
    // Find first pending task that is due after 'now' but before 'now + 24h'
    final upcomingTasks = tasks.where((t) => 
      !t.isCompleted && 
      t.dueDate.isAfter(now) && 
      t.dueDate.isBefore(next24Hours)
    ).toList();
    
    if (upcomingTasks.isEmpty) return const SizedBox.shrink(); // Hidden if empty
    
    final nextTask = upcomingTasks.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32), // Spacer below
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.planner),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const PhosphorIcon(PhosphorIconsRegular.clockUser, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Task • ${DateFormat('h:mm a').format(nextTask.dueDate)}',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextTask.title,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PhosphorIcon(PhosphorIconsRegular.caretRight, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context, WidgetRef ref) {
    final pulse = ref.watch(wellnessPulseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Wellness Tools", style: AppTextStyles.headingMedium),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HilwayCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                color: AppColors.surface,
                onTap: () => context.push('/burnout-assessment'),
                child: WellnessGauge(
                  score: pulse.resilienceScore,
                  level: pulse.level,
                  label: pulse.label,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _ToolCard(
                    title: "Breathing",
                    subtitle: "Relax & center",
                    iconData: PhosphorIconsRegular.wind,
                    color: AppColors.primary,
                    route: AppRoutes.breathing,
                    compact: true,
                  ),
                  const SizedBox(height: 16),
                  _ToolCard(
                    title: "Planner",
                    subtitle: "Next duty",
                    iconData: PhosphorIconsRegular.calendarCheck,
                    color: AppColors.accent,
                    route: AppRoutes.planner,
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Hero(
                tag: 'kelly_chat_fab',
                child: Material(
                  color: Colors.transparent,
                  child: _ToolCard(
                    title: "Talk to Kelly",
                    subtitle: "Your AI companion",
                    iconData: PhosphorIconsRegular.chatTeardropDots,
                    color: AppColors.secondary,
                    route: AppRoutes.chatbot,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ToolCard(
                title: "Crisis Support",
                subtitle: "Get help instantly",
                iconData: PhosphorIconsRegular.phoneCall,
                color: AppColors.crisis,
                route: '/crisis',
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color color;
  final String route;
  final bool compact;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.color,
    required this.route,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return HilwayCard(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 12 : 20,
      ),
      color: AppColors.surface,
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(iconData, color: color, size: compact ? 22 : 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 14 : 16,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (compact)
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              color: AppColors.textTertiary,
              size: 16,
            ),
        ],
      ),
    );
  }
}

// ── Floating Emoji Animation ──────────────────────────────────────────────
class FloatingEmoji extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  const FloatingEmoji({super.key, required this.emoji, this.isSelected = false});

  @override
  State<FloatingEmoji> createState() => _FloatingEmojiState();
}

class _FloatingEmojiState extends State<FloatingEmoji> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yOffset;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _yOffset = Tween<double>(begin: 0, end: -4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // If selected, pulse slightly more or rotate
        double finalY = _yOffset.value;
        double finalScale = widget.isSelected ? (_scale.value + 0.05) : _scale.value;
        
        return Transform.translate(
          offset: Offset(0, finalY),
          child: Transform.scale(
            scale: finalScale,
            child: Text(
              widget.emoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
        );
      },
    );
  }
}