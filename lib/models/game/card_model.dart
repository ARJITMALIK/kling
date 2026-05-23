import 'troop_data.dart';

class CardModel {
  final TroopType troopType;

  const CardModel({required this.troopType});

  TroopData get data => TroopData.get(troopType);
  String get name => data.name;
  String get emoji => data.emoji;
  int get bubCost => data.bubCost;
  bool get isSpell => data.isSpell;
}

class DeckModel {
  final List<CardModel> cards;
  int _nextIndex = 0;

  DeckModel({required this.cards}) {
    cards.shuffle();
  }

  /// Default 8-card deck with all troop types
  factory DeckModel.defaultDeck() {
    return DeckModel(
      cards: TroopType.values
          .map((type) => CardModel(troopType: type))
          .toList(),
    );
  }

  /// Draw the next card from the deck (cycles)
  CardModel drawNext() {
    final card = cards[_nextIndex % cards.length];
    _nextIndex++;
    return card;
  }

  /// Peek at next card without drawing
  CardModel peekNext() {
    return cards[_nextIndex % cards.length];
  }
}

class HandModel {
  final List<CardModel> cards;
  CardModel? nextCard;

  HandModel({required this.cards, this.nextCard});

  /// Replace a card at index with the next card from the deck
  void replaceCard(int index, CardModel newCard) {
    if (index >= 0 && index < cards.length) {
      cards[index] = newCard;
    }
  }
}
