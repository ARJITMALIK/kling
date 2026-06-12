import '../models/user_model.dart';
import '../models/couple_model.dart';
import '../models/emote_model.dart';
import '../models/game/game_state.dart';

/// Abstract API contract. Implement with MockApiService for dev,
/// RealApiService for production (your Go/NestJS backend).
abstract class ApiService {
  // ─── Auth ───
  Future<UserModel> register(String email, String password, String displayName);
  Future<UserModel> login(String email, String password);
  Future<void> logout();
  Future<UserModel> getMe();

  // ─── Couple ───
  Future<String> generateInviteCode();
  Future<CoupleModel> joinCouple(String inviteCode);
  Future<void> cancelRequest();
  Future<CoupleModel?> getCouple();
  Future<void> unpair();

  // ─── Dashboard Data ───
  Future<void> updateBattery(int level);
  Future<void> updateLocation(double lat, double lng);
  Future<void> updateMood(String emoji);
  Future<void> updateSong(String title, String artist);
  Future<UserModel?> getPartnerStatus();
  Future<CoupleModel?> getCoupleStats();
  Future<CoupleStreaks?> getStreaks();
  Future<void> sendGoodMorning();
  Future<void> sendGoodNight();
  Future<MissingMeter?> getMissingMeter();
  Future<void> pingPartner();
  Future<List<LocationAlert>> getLocationAlerts();

  // ─── Emotes ───
  Future<void> sendEmote(String emoteId);
  Future<List<ReceivedEmote>> getReceivedEmotes();

  // ─── Game ───
  Future<void> requestBattle();
  Future<void> acceptBattle();
  Future<GameStateModel?> getActiveGame();
}

class LocationAlert {
  final String place;
  final DateTime partnerVisitDate;
  final double lat;
  final double lng;

  const LocationAlert({
    required this.place,
    required this.partnerVisitDate,
    required this.lat,
    required this.lng,
  });

  factory LocationAlert.fromJson(Map<String, dynamic> json) {
    return LocationAlert(
      place: json['place'] as String,
      partnerVisitDate: DateTime.parse(json['partnerVisitDate'] as String),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}

class ReceivedEmote {
  final String emoteId;
  final DateTime sentAt;

  const ReceivedEmote({required this.emoteId, required this.sentAt});

  factory ReceivedEmote.fromJson(Map<String, dynamic> json) {
    return ReceivedEmote(
      emoteId: json['emoteId'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}
