import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/couple_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/widget_service.dart';
import 'auth_provider.dart';

// ─── Couple State ───

class CoupleState {
  final CoupleModel? couple;
  final UserModel? partner;
  final List<LocationAlert> locationAlerts;
  final bool isLoading;
  final String? error;

  const CoupleState({
    this.couple,
    this.partner,
    this.locationAlerts = const [],
    this.isLoading = false,
    this.error,
  });

  CoupleState copyWith({
    CoupleModel? couple,
    UserModel? partner,
    List<LocationAlert>? locationAlerts,
    bool? isLoading,
    String? error,
  }) {
    return CoupleState(
      couple: couple ?? this.couple,
      partner: partner ?? this.partner,
      locationAlerts: locationAlerts ?? this.locationAlerts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CoupleNotifier extends StateNotifier<CoupleState> {
  final ApiService _api;

  CoupleNotifier(this._api) : super(const CoupleState());

  Future<void> loadCoupleData() async {
    state = state.copyWith(isLoading: true);
    try {
      final couple = await _api.getCouple();
      final partner = await _api.getPartnerStatus();
      final alerts = await _api.getLocationAlerts();
      state = CoupleState(
        couple: couple,
        partner: partner,
        locationAlerts: alerts,
      );
      
      // Sync native widgets
      await WidgetService.syncPartnerStats(partner);
      
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String> generateInviteCode() async {
    return await _api.generateInviteCode();
  }

  Future<bool> joinCouple(String code) async {
    try {
      final couple = await _api.joinCouple(code);
      state = state.copyWith(couple: couple);
      await loadCoupleData();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> unpair() async {
    await _api.unpair();
    state = const CoupleState();
  }

  Future<void> updateMood(String emoji) async {
    await _api.updateMood(emoji);
  }

  Future<void> updateSong(String title, String artist) async {
    await _api.updateSong(title, artist);
  }

  Future<void> sendGoodMorning() async {
    await _api.sendGoodMorning();
  }

  Future<void> sendGoodNight() async {
    await _api.sendGoodNight();
  }

  Future<void> pingPartner() async {
    await _api.pingPartner();
  }

  Future<void> requestBattle() async {
    await _api.requestBattle();
  }
}

final coupleProvider = StateNotifierProvider<CoupleNotifier, CoupleState>((ref) {
  return CoupleNotifier(ref.read(apiServiceProvider));
});
