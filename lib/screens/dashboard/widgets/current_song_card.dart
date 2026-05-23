import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/user_model.dart';
import '../../../widgets/glass_card.dart';

class CurrentSongCard extends StatefulWidget {
  final SongEntry? mySong;
  final SongEntry? partnerSong;
  final String partnerName;

  const CurrentSongCard({
    super.key,
    this.mySong,
    this.partnerSong,
    required this.partnerName,
  });

  @override
  State<CurrentSongCard> createState() => _CurrentSongCardState();
}

class _CurrentSongCardState extends State<CurrentSongCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _eqController;

  @override
  void initState() {
    super.initState();
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _eqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My song
          if (widget.partnerSong != null) ...[
            Row(
              children: [
                // Animated equalizer
                AnimatedBuilder(
                  animation: _eqController,
                  builder: (context, _) => Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(4, (i) {
                      final offset = i * 0.15;
                      final value = (_eqController.value + offset).clamp(0.0, 1.0);
                      final heights = [0.4, 0.7, 0.5, 0.8];
                      final h = 8 + (heights[i] * value * 14);
                      return Container(
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentPink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.partnerName} is listening to',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.partnerSong!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.partnerSong!.artist,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientLove,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 22),
                ),
              ],
            ),
          ] else ...[
            const Row(
              children: [
                Text('🎵', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'No song playing',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
