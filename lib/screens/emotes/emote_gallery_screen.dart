import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/emote_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/bottom_nav.dart';
import '../../widgets/glass_card.dart';

class EmoteGalleryScreen extends ConsumerStatefulWidget {
  const EmoteGalleryScreen({super.key});

  @override
  ConsumerState<EmoteGalleryScreen> createState() => _EmoteGalleryScreenState();
}

class _EmoteGalleryScreenState extends ConsumerState<EmoteGalleryScreen> {
  EmoteCategory _selectedCategory = EmoteCategory.love;
  String? _playingEmote;

  @override
  Widget build(BuildContext context) {
    // Include all non-battle categories
    final categories = EmoteCategory.values
        .where((c) => c != EmoteCategory.battle)
        .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBg),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.gradientLove.createShader(bounds),
                          child: const Text(
                            'Emotes',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Tap to send 💕',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category tabs
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = cat == _selectedCategory;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentPink.withValues(alpha: 0.2)
                                  : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentPink.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(cat.icon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  cat.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.accentPink
                                        : AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Emote grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: AppEmotes.byCategory(_selectedCategory).length,
                      itemBuilder: (context, index) {
                        final emote = AppEmotes.byCategory(_selectedCategory)[index];
                        return _EmoteCard(
                          emote: emote,
                          onTap: () => _sendEmote(emote),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Full-screen emote animation
              if (_playingEmote != null)
                _FullScreenEmote(
                  emoteId: _playingEmote!,
                  onDone: () => setState(() => _playingEmote = null),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  void _sendEmote(EmoteModel emote) {
    setState(() => _playingEmote = emote.id);
    // In production, also call API to send emote
    ref.read(apiServiceProvider).sendEmote(emote.id);
  }
}

class _EmoteCard extends StatelessWidget {
  final EmoteModel emote;
  final VoidCallback onTap;

  const _EmoteCard({required this.emote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emote.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              emote.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenEmote extends StatefulWidget {
  final String emoteId;
  final VoidCallback onDone;

  const _FullScreenEmote({required this.emoteId, required this.onDone});

  @override
  State<_FullScreenEmote> createState() => _FullScreenEmoteState();
}

class _FullScreenEmoteState extends State<_FullScreenEmote>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emote = AppEmotes.all.where((e) => e.id == widget.emoteId).firstOrNull;
    if (emote == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scale = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 15),
          TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 10),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 3.0), weight: 20),
        ]).evaluate(_controller);

        final opacity = TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 65),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
        ]).evaluate(_controller);

        return GestureDetector(
          onTap: widget.onDone,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6 * opacity),
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emote.emoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emote.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: opacity),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sent! 💕',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.accentPink.withValues(alpha: opacity),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}
