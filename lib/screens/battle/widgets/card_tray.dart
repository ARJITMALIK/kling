import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/game/card_model.dart';

class CardTray extends StatelessWidget {
  final HandModel hand;
  final double currentBub;
  final int? selectedIndex;
  final CardModel? nextCard;
  final ValueChanged<int> onCardTap;

  const CardTray({
    super.key,
    required this.hand,
    required this.currentBub,
    this.selectedIndex,
    this.nextCard,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Next card preview
        Column(
          children: [
            const Text(
              'Next:',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 36,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Center(
                child: Text(
                  nextCard?.emoji ?? '?',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
        // Hand cards
        ...List.generate(hand.cards.length, (index) {
          final card = hand.cards[index];
          final canAfford = currentBub >= card.bubCost;
          final isSelected = selectedIndex == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: canAfford ? () => onCardTap(index) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: isSelected ? 72 : 64,
                  transform: isSelected
                      ? Matrix4.translationValues(0, -8, 0)
                      : Matrix4.identity(),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? card.data.color.withValues(alpha: 0.3)
                        : canAfford
                            ? AppColors.bgCard
                            : AppColors.bgCard.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? card.data.color
                          : canAfford
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: card.data.color.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.emoji,
                        style: TextStyle(
                          fontSize: 20,
                          color: canAfford ? null : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Bub cost badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? AppColors.bubColor.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${card.bubCost}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: canAfford
                                ? AppColors.bubColor
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
