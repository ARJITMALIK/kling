import 'dart:math';
import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../models/game/game_state.dart';
import 'api_service.dart';

/// Mock implementation for development — returns fake data.
/// Replace with RealApiService when your Go/NestJS backend is ready.
class MockApiService implements ApiService {
  UserModel? _currentUser;
  CoupleModel? _couple;
  bool _isPaired = false;

  final _mockPartner = UserModel(
    uid: 'partner-001',
    email: 'poornima@cling.app',
    displayName: 'Poornima 💕',
    coupleId: 'couple-001',
    partnerId: 'user-001',
    battery: 72,
    lat: 28.6139,
    lng: 77.2090,
    currentMood: MoodEntry(emoji: '🥰', setAt: DateTime.now().subtract(const Duration(hours: 2))),
    currentSong: const SongEntry(title: 'Perfect', artist: 'Ed Sheeran'),
    lastOpenedAt: DateTime.now().subtract(const Duration(minutes: 15)),
    createdAt: DateTime(2024, 6, 15),
  );

  // ─── Auth ───

  @override
  Future<UserModel> register(String email, String password, String displayName) async {
    await _delay();
    _currentUser = UserModel(
      uid: 'user-001',
      email: email,
      displayName: displayName,
      inviteCode: _generateCode(),
      createdAt: DateTime.now(),
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    await _delay();
    _currentUser = UserModel(
      uid: 'user-001',
      email: email,
      displayName: 'Arjit',
      inviteCode: 'ABC123',
      coupleId: _isPaired ? 'couple-001' : null,
      partnerId: _isPaired ? 'partner-001' : null,
      battery: 85,
      lat: 28.6292,
      lng: 77.2182,
      currentMood: MoodEntry(emoji: '😊', setAt: DateTime.now()),
      currentSong: const SongEntry(title: 'Lover', artist: 'Taylor Swift'),
      createdAt: DateTime(2024, 6, 15),
    );
    _isPaired = true;
    _initCouple();
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await _delay();
    _currentUser = null;
  }

  @override
  Future<UserModel> getMe() async {
    await _delay();
    if (_currentUser == null) throw Exception('Not logged in');
    return _currentUser!;
  }

  // ─── Couple ───

  @override
  Future<String> generateInviteCode() async {
    await _delay();
    final code = _generateCode();
    _currentUser = _currentUser?.copyWith(inviteCode: code);
    return code;
  }

  @override
  Future<CoupleModel> joinCouple(String inviteCode) async {
    await _delay(ms: 1500);
    _isPaired = true;
    _currentUser = _currentUser?.copyWith(
      coupleId: 'couple-001',
      partnerId: 'partner-001',
    );
    _initCouple();
    return _couple!;
  }

  @override
  Future<CoupleModel?> getCouple() async {
    await _delay();
    return _couple;
  }

  @override
  Future<void> unpair() async {
    await _delay();
    _isPaired = false;
    _couple = null;
    _currentUser = _currentUser?.copyWith(coupleId: null, partnerId: null);
  }

  // ─── Dashboard ───

  @override
  Future<void> updateBattery(int level) async {
    await _delay();
    _currentUser = _currentUser?.copyWith(battery: level);
  }

  @override
  Future<void> updateLocation(double lat, double lng) async {
    await _delay();
    _currentUser = _currentUser?.copyWith(lat: lat, lng: lng);
  }

  @override
  Future<void> updateMood(String emoji) async {
    await _delay();
    _currentUser = _currentUser?.copyWith(
      currentMood: MoodEntry(emoji: emoji, setAt: DateTime.now()),
    );
  }

  @override
  Future<void> updateSong(String title, String artist) async {
    await _delay();
    _currentUser = _currentUser?.copyWith(
      currentSong: SongEntry(title: title, artist: artist),
    );
  }

  @override
  Future<UserModel?> getPartnerStatus() async {
    await _delay();
    if (!_isPaired) return null;
    return _mockPartner;
  }

  @override
  Future<CoupleModel?> getCoupleStats() async {
    await _delay();
    return _couple;
  }

  @override
  Future<CoupleStreaks?> getStreaks() async {
    await _delay();
    return _couple?.streaks;
  }

  @override
  Future<void> sendGoodMorning() async {
    await _delay();
  }

  @override
  Future<void> sendGoodNight() async {
    await _delay();
  }

  @override
  Future<MissingMeter?> getMissingMeter() async {
    await _delay();
    return _couple?.missingMeter;
  }

  @override
  Future<void> pingPartner() async {
    await _delay();
  }

  @override
  Future<List<LocationAlert>> getLocationAlerts() async {
    await _delay();
    return [
      LocationAlert(
        place: 'Starbucks, Connaught Place',
        partnerVisitDate: DateTime.now().subtract(const Duration(days: 3)),
        lat: 28.6314,
        lng: 77.2167,
      ),
      LocationAlert(
        place: 'Central Park',
        partnerVisitDate: DateTime.now().subtract(const Duration(days: 1)),
        lat: 28.6280,
        lng: 77.2200,
      ),
    ];
  }

  // ─── Emotes ───

  @override
  Future<void> sendEmote(String emoteId) async {
    await _delay();
  }

  @override
  Future<List<ReceivedEmote>> getReceivedEmotes() async {
    await _delay();
    return [
      ReceivedEmote(emoteId: 'bear_hug', sentAt: DateTime.now().subtract(const Duration(hours: 1))),
      ReceivedEmote(emoteId: 'kiss', sentAt: DateTime.now().subtract(const Duration(hours: 3))),
    ];
  }

  // ─── Game ───

  @override
  Future<void> requestBattle() async {
    await _delay();
  }

  @override
  Future<void> acceptBattle() async {
    await _delay();
  }

  @override
  Future<GameStateModel?> getActiveGame() async {
    await _delay();
    return null;
  }

  // ─── Helpers ───

  void _initCouple() {
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    _couple = CoupleModel(
      coupleId: 'couple-001',
      user1Id: 'user-001',
      user2Id: 'partner-001',
      firstMeetDate: DateTime(2023, 2, 14),
      togetherSince: DateTime(2023, 6, 15),
      streaks: CoupleStreaks(
        general: StreakData(count: 45, lastDate: todayStr, user1Done: true, user2Done: true),
        goodMorning: StreakData(count: 12, lastDate: todayStr, user1Done: true, user2Done: false),
        goodNight: StreakData(count: 30, lastDate: todayStr, user1Done: true, user2Done: true),
      ),
      missingMeter: const MissingMeter(
        user1Score: 42,
        user2Score: 37,
        weekStart: '2026-05-12',
      ),
      gameStats: const GameStats(
        user1Wins: 15,
        user2Wins: 12,
        draws: 3,
      ),
    );
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _delay({int ms = 500}) async {
    await Future.delayed(Duration(milliseconds: ms));
  }
}


