class TowerData {
  final TowerType type;
  final String name;
  final int hp;
  final int dps;
  final double range;

  const TowerData({
    required this.type,
    required this.name,
    required this.hp,
    required this.dps,
    required this.range,
  });

  static const TowerData kingTower = TowerData(
    type: TowerType.king,
    name: 'King Tower',
    hp: 2500,
    dps: 80,
    range: 6.5,
  );

  static const TowerData princessTower = TowerData(
    type: TowerType.princess,
    name: 'Princess Tower',
    hp: 1400,
    dps: 60,
    range: 7.5,
  );
}

enum TowerType { king, princess }
