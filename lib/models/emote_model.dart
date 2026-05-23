class EmoteModel {
  final String id;
  final String name;
  final String emoji;
  final EmoteCategory category;
  final bool isUnlocked;

  const EmoteModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.isUnlocked = true,
  });
}

enum EmoteCategory {
  love('Love', '💕'),
  missYou('Miss You', '🥺'),
  goodMorning('Good Morning', '☀️'),
  goodNight('Good Night', '🌙'),
  playful('Playful', '😜'),
  reactions('Reactions', '😲'),
  battle('Battle', '⚔️');

  final String label;
  final String icon;
  const EmoteCategory(this.label, this.icon);
}

// Pre-configured emotes
class AppEmotes {
  static const List<EmoteModel> all = [
    // Love
    EmoteModel(id: 'flying_hearts', name: 'Flying Hearts', emoji: '💕', category: EmoteCategory.love),
    EmoteModel(id: 'bear_hug', name: 'Bear Hug', emoji: '🤗', category: EmoteCategory.love),
    EmoteModel(id: 'kiss', name: 'Kiss', emoji: '😘', category: EmoteCategory.love),
    EmoteModel(id: 'heart_eyes', name: 'Heart Eyes', emoji: '😍', category: EmoteCategory.love),
    EmoteModel(id: 'love_letter', name: 'Love Letter', emoji: '💌', category: EmoteCategory.love),

    // Miss You
    EmoteModel(id: 'lonely_bear', name: 'Lonely Bear', emoji: '🧸', category: EmoteCategory.missYou),
    EmoteModel(id: 'rain_window', name: 'Rain Window', emoji: '🌧️', category: EmoteCategory.missYou),
    EmoteModel(id: 'counting_stars', name: 'Counting Stars', emoji: '⭐', category: EmoteCategory.missYou),
    EmoteModel(id: 'pleading', name: 'Come Back', emoji: '🥺', category: EmoteCategory.missYou),

    // Good Morning
    EmoteModel(id: 'sunrise', name: 'Sunrise', emoji: '🌅', category: EmoteCategory.goodMorning),
    EmoteModel(id: 'coffee', name: 'Coffee Cup', emoji: '☕', category: EmoteCategory.goodMorning),
    EmoteModel(id: 'stretch', name: 'Stretching', emoji: '🙆', category: EmoteCategory.goodMorning),
    EmoteModel(id: 'sunshine', name: 'Sunshine', emoji: '☀️', category: EmoteCategory.goodMorning),

    // Good Night
    EmoteModel(id: 'moon_stars', name: 'Moon & Stars', emoji: '🌙', category: EmoteCategory.goodNight),
    EmoteModel(id: 'sleeping', name: 'Sleeping', emoji: '😴', category: EmoteCategory.goodNight),
    EmoteModel(id: 'candle', name: 'Candle', emoji: '🕯️', category: EmoteCategory.goodNight),
    EmoteModel(id: 'blanket', name: 'Cozy Blanket', emoji: '🛏️', category: EmoteCategory.goodNight),

    // Playful
    EmoteModel(id: 'tongue_out', name: 'Tongue Out', emoji: '😜', category: EmoteCategory.playful),
    EmoteModel(id: 'pillow_fight', name: 'Pillow Fight', emoji: '🪶', category: EmoteCategory.playful),
    EmoteModel(id: 'tickle', name: 'Tickle', emoji: '🤭', category: EmoteCategory.playful),
    EmoteModel(id: 'dance', name: 'Dance', emoji: '💃', category: EmoteCategory.playful),

    // Reactions
    EmoteModel(id: 'blush', name: 'Blush', emoji: '☺️', category: EmoteCategory.reactions),
    EmoteModel(id: 'eye_roll', name: 'Eye Roll', emoji: '🙄', category: EmoteCategory.reactions),
    EmoteModel(id: 'fake_angry', name: 'Fake Angry', emoji: '😤', category: EmoteCategory.reactions),
    EmoteModel(id: 'dramatic_cry', name: 'Dramatic Cry', emoji: '😭', category: EmoteCategory.reactions),
    EmoteModel(id: 'mind_blown', name: 'Mind Blown', emoji: '🤯', category: EmoteCategory.reactions),

    // Battle (in-game)
    EmoteModel(id: 'good_luck', name: 'Good Luck!', emoji: '🍀', category: EmoteCategory.battle),
    EmoteModel(id: 'well_played', name: 'Well Played!', emoji: '👏', category: EmoteCategory.battle),
    EmoteModel(id: 'miss_you_battle', name: 'Miss You!', emoji: '💕', category: EmoteCategory.battle),
    EmoteModel(id: 'oops', name: 'Oops!', emoji: '😅', category: EmoteCategory.battle),
    EmoteModel(id: 'haha', name: 'Haha!', emoji: '😂', category: EmoteCategory.battle),
    EmoteModel(id: 'wow', name: 'Wow!', emoji: '😮', category: EmoteCategory.battle),
  ];

  static List<EmoteModel> byCategory(EmoteCategory category) {
    return all.where((e) => e.category == category).toList();
  }

  static List<EmoteModel> get battleEmotes => byCategory(EmoteCategory.battle);
}
