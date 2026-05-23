import 'package:flutter/material.dart';

enum TroopType {
  loveKnight,
  cupidArcher,
  teddyTank,
  heartbreakHorde,
  roseBomber,
  butterflySwarm,
  healingAngel,
  arrowRain,
}

enum TroopTargetType { melee, ranged, splash, healer, spell }

enum TroopSpeed { veryFast, fast, medium, slow }

class TroopData {
  final TroopType type;
  final String name;
  final String emoji;
  final int bubCost;
  final int hp;
  final int dps;
  final double range;
  final TroopSpeed speed;
  final TroopTargetType targetType;
  final int spawnCount; // How many units spawn per card
  final Color color;
  final String description;

  const TroopData({
    required this.type,
    required this.name,
    required this.emoji,
    required this.bubCost,
    required this.hp,
    required this.dps,
    required this.range,
    required this.speed,
    required this.targetType,
    this.spawnCount = 1,
    required this.color,
    required this.description,
  });

  double get speedValue {
    switch (speed) {
      case TroopSpeed.veryFast:
        return 3.0;
      case TroopSpeed.fast:
        return 2.2;
      case TroopSpeed.medium:
        return 1.5;
      case TroopSpeed.slow:
        return 0.8;
    }
  }

  bool get isSpell => targetType == TroopTargetType.spell;

  static const Map<TroopType, TroopData> all = {
    TroopType.loveKnight: TroopData(
      type: TroopType.loveKnight,
      name: 'Love Knight',
      emoji: '🛡️',
      bubCost: 4,
      hp: 800,
      dps: 120,
      range: 1.0,
      speed: TroopSpeed.medium,
      targetType: TroopTargetType.melee,
      color: Color(0xFF4A90D9),
      description: 'A sturdy knight with a heart-shaped shield.',
    ),
    TroopType.cupidArcher: TroopData(
      type: TroopType.cupidArcher,
      name: 'Cupid Archer',
      emoji: '🏹',
      bubCost: 3,
      hp: 300,
      dps: 80,
      range: 5.5,
      speed: TroopSpeed.medium,
      targetType: TroopTargetType.ranged,
      color: Color(0xFFFF6B9D),
      description: 'Shoots heart-tipped arrows from afar.',
    ),
    TroopType.teddyTank: TroopData(
      type: TroopType.teddyTank,
      name: 'Teddy Tank',
      emoji: '🧸',
      bubCost: 5,
      hp: 1400,
      dps: 50,
      range: 1.0,
      speed: TroopSpeed.slow,
      targetType: TroopTargetType.melee,
      color: Color(0xFF8B6914),
      description: 'A giant teddy bear that absorbs tons of damage.',
    ),
    TroopType.heartbreakHorde: TroopData(
      type: TroopType.heartbreakHorde,
      name: 'Heartbreak Horde',
      emoji: '💔',
      bubCost: 3,
      hp: 100,
      dps: 40,
      range: 1.0,
      speed: TroopSpeed.fast,
      targetType: TroopTargetType.melee,
      spawnCount: 4,
      color: Color(0xFFFF4466),
      description: 'Four broken hearts swarm the enemy.',
    ),
    TroopType.roseBomber: TroopData(
      type: TroopType.roseBomber,
      name: 'Rose Bomber',
      emoji: '🌹',
      bubCost: 4,
      hp: 400,
      dps: 180,
      range: 4.5,
      speed: TroopSpeed.medium,
      targetType: TroopTargetType.splash,
      color: Color(0xFFE83E3E),
      description: 'Throws explosive roses dealing area damage.',
    ),
    TroopType.butterflySwarm: TroopData(
      type: TroopType.butterflySwarm,
      name: 'Butterfly Swarm',
      emoji: '🦋',
      bubCost: 2,
      hp: 60,
      dps: 25,
      range: 1.0,
      speed: TroopSpeed.veryFast,
      targetType: TroopTargetType.melee,
      spawnCount: 3,
      color: Color(0xFFC084FC),
      description: 'Cheap and fast — great for cycling cards.',
    ),
    TroopType.healingAngel: TroopData(
      type: TroopType.healingAngel,
      name: 'Healing Angel',
      emoji: '👼',
      bubCost: 3,
      hp: 200,
      dps: 0, // Heals instead
      range: 5.0,
      speed: TroopSpeed.medium,
      targetType: TroopTargetType.healer,
      color: Color(0xFF4ADE80),
      description: 'Heals nearby friendly troops.',
    ),
    TroopType.arrowRain: TroopData(
      type: TroopType.arrowRain,
      name: 'Arrow Rain',
      emoji: '🏹',
      bubCost: 3,
      hp: 0, // Spell
      dps: 250, // Total damage
      range: 0, // Targeted area
      speed: TroopSpeed.medium,
      targetType: TroopTargetType.spell,
      color: Color(0xFFFF8C42),
      description: 'Rains arrows on an area dealing instant damage.',
    ),
  };

  static TroopData get(TroopType type) => all[type]!;
}
