import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/models/mood_log.dart';
import '../../mood_tracking/providers/mood_provider.dart';
import '../providers/kelly_state_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_safety_provider.dart';
import '../providers/chat_session_provider.dart';
import '../providers/chat_tutorial_provider.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/priority_crisis_bar.dart';
import '../widgets/chat_tutorial_overlay.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Send the message through the provider (handles Gemini & sentiment)
    ref.read(chatMessagesProvider.notifier).sendMessage(text);
    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Kelly's current emotion for the Hero Header asset
    final currentEmotion = ref.watch(kellyEmotionProvider);
    // Watch Chat State
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(chatLoadingProvider);
    final isInitializing = ref.watch(chatInitializingProvider);
    // Watch crisis safety state
    final isCrisisActive = ref.watch(isCrisisActiveProvider);
    // Watch today's mood to drive context-aware chips
    final todayMood = ref.watch(todayMoodProvider);

    // Auto-scroll when new messages arrive
    ref.listen(chatMessagesProvider, (_, __) => Future.delayed(const Duration(milliseconds: 100), _scrollToBottom));
    ref.listen(chatLoadingProvider, (_, __) => Future.delayed(const Duration(milliseconds: 100), _scrollToBottom));

    // Watch tutorial state
    final showTutorial = ref.watch(chatTutorialProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header & Hero Transition ──────────────────────────────
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const PhosphorIcon(PhosphorIconsRegular.x, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'New Chat',
                    icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple, color: AppColors.textSecondary),
                    onPressed: () {
                      ref.read(currentSessionIdProvider.notifier).state = null;
                      _messageController.clear();
                    },
                  ),
                  IconButton(
                    tooltip: 'History',
                    icon: const PhosphorIcon(PhosphorIconsRegular.clock, color: AppColors.textSecondary),
                    onPressed: () => context.push(AppRoutes.chatHistory),
                  ),
                  IconButton(
                    tooltip: 'How to use',
                    icon: const PhosphorIcon(PhosphorIconsRegular.question, color: AppColors.textSecondary),
                    onPressed: () => ref.read(chatTutorialProvider.notifier).showTutorial(),
                  ),
                ],
              ),
            ),
            
            Hero(
              tag: 'kelly_chat_fab',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  alignment: Alignment.center,
                  // In phase 4.5+, this gets swapped with RiveAnimation.network or local files
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Tooltip(
                      message: 'Kelly state: $currentEmotion',
                      child: const PhosphorIcon(PhosphorIconsRegular.firstAid, size: 72, color: AppColors.accent),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // ── Chat List Area ──────────────────────────────────────────
            Expanded(
              child: isInitializing
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Kelly is getting ready...',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: messages.length + (isLoading ? 1 : 0) + 1, // +1 for security banner
                itemBuilder: (context, index) {
                  // Security Banner is the first item
                  if (index == 0) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "🔒 Your conversations are stored locally.",
                          style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    );
                  }

                  // Typing Indicator is the last item if loading
                  if (isLoading && index == messages.length + 1) {
                    return const TypingIndicator();
                  }

                  final message = messages[index - 1];
                  return ChatMessageBubble(message: message);
                },
              ),
            ),
            
            // ── Crisis Bar (persistent once triggered) ─────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: isCrisisActive
                  ? const PriorityCrisisBar(key: ValueKey('crisis_bar'))
                  : const SizedBox.shrink(key: ValueKey('crisis_bar_hidden')),
            ),

            // ── Quick Replies (Context Aware) ───────────────────────────────
            if (!isLoading && messages.isNotEmpty)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _buildQuickReplies(currentEmotion, todayMood),
              ),
            
            // ── Input Area ──────────────────────────────────────────────────
            _buildInputArea(),
          ],
        ),
        
        // ── Tutorial Overlay ──────────────────────────────────────
        if (showTutorial) const ChatTutorialOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies(String emotion, MoodLog? todayMood) {
    final bool moodLogged = todayMood != null;
    List<Widget> chips = [];

    if (emotion == AppConstants.kellyConcerned || emotion == AppConstants.kellySad) {
      // Feeling bad: offer breathing, or crying-it-out with Kelly
      chips = [
        _buildChip("Try Breathing", PhosphorIconsRegular.wind, openRoute: AppRoutes.breathing),
        _buildChip("I'm overwhelmed", PhosphorIconsRegular.warningCircle, openRoute: AppRoutes.crisis),
      ];
    } else if (emotion == AppConstants.kellyHappy || emotion == AppConstants.kellyExcited) {
      // Feeling good: mood logging if not done, else show progress
      chips = [
        if (!moodLogged)
          _buildChip("Log my mood 😄", PhosphorIconsRegular.smiley, openRoute: AppRoutes.moodTracking)
        else
          _buildChip("View my Progress", PhosphorIconsRegular.trendUp, openRoute: AppRoutes.progress),
        _buildChip("Thanks, Kelly!", PhosphorIconsRegular.heart),
      ];
    } else {
      // Default / neutral: context-aware shortcuts
      chips = [
        _buildChip("I feel stressed", PhosphorIconsRegular.cloudRain),
        if (!moodLogged)
          _buildChip("Log my mood", PhosphorIconsRegular.smiley, openRoute: AppRoutes.moodTracking)
        else
          _buildChip("Tell me a joke", PhosphorIconsRegular.smileyWink),
      ];
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, {String? openRoute}) {
    return ActionChip(
      avatar: PhosphorIcon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: AppTextStyles.labelMedium),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        if (openRoute != null) {
          // Navigate directly to the target feature screen
          context.push(openRoute);
        } else {
          // Send the chip label as a message to Kelly
          _messageController.text = label;
          _sendMessage();
        }
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Message Kelly...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _sendMessage,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}