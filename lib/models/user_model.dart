class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? coupleId;
  final String? partnerId;
  final String? inviteCode;
  final String? partnerInviteCode;
  final String? pairingStatus;
  final int? battery;
  final String? batteryStatus;
  final double? lat;
  final double? lng;
  final MoodEntry? currentMood;
  final SongEntry? currentSong;
  final DateTime? lastOpenedAt;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.coupleId,
    this.partnerId,
    this.inviteCode,
    this.partnerInviteCode,
    this.pairingStatus,
    this.battery,
    this.batteryStatus,
    this.lat,
    this.lng,
    this.currentMood,
    this.currentSong,
    this.lastOpenedAt,
    required this.createdAt,
  });

  bool get isPaired => coupleId != null && partnerId != null && pairingStatus == 'ACTIVE';

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? coupleId,
    String? partnerId,
    String? inviteCode,
    String? partnerInviteCode,
    String? pairingStatus,
    int? battery,
    String? batteryStatus,
    double? lat,
    double? lng,
    MoodEntry? currentMood,
    SongEntry? currentSong,
    DateTime? lastOpenedAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coupleId: coupleId ?? this.coupleId,
      partnerId: partnerId ?? this.partnerId,
      inviteCode: inviteCode ?? this.inviteCode,
      partnerInviteCode: partnerInviteCode ?? this.partnerInviteCode,
      pairingStatus: pairingStatus ?? this.pairingStatus,
      battery: battery ?? this.battery,
      batteryStatus: batteryStatus ?? this.batteryStatus,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      currentMood: currentMood ?? this.currentMood,
      currentSong: currentSong ?? this.currentSong,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: (json['uid'] ?? json['id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      displayName: (json['displayName'] ?? '') as String,
      avatarUrl: json['avatarUrl'] as String?,
      coupleId: json['coupleId'] as String?,
      partnerId: json['partnerId'] as String?,
      inviteCode: json['inviteCode'] as String?,
      partnerInviteCode: json['partnerInviteCode'] as String?,
      pairingStatus: json['pairingStatus'] as String?,
      battery: json['battery'] as int?,
      batteryStatus: json['batteryStatus'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      currentMood: json['currentMood'] != null
          ? MoodEntry.fromJson(json['currentMood'] as Map<String, dynamic>)
          : null,
      currentSong: json['currentSong'] != null
          ? SongEntry.fromJson(json['currentSong'] as Map<String, dynamic>)
          : null,
      lastOpenedAt: json['lastOpenedAt'] != null
          ? DateTime.parse(json['lastOpenedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'coupleId': coupleId,
      'partnerId': partnerId,
      'inviteCode': inviteCode,
      'partnerInviteCode': partnerInviteCode,
      'pairingStatus': pairingStatus,
      'battery': battery,
      'batteryStatus': batteryStatus,
      'lat': lat,
      'lng': lng,
      'currentMood': currentMood?.toJson(),
      'currentSong': currentSong?.toJson(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MoodEntry {
  final String emoji;
  final DateTime setAt;

  const MoodEntry({required this.emoji, required this.setAt});

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      emoji: json['emoji'] as String,
      setAt: DateTime.parse(json['setAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'setAt': setAt.toIso8601String(),
      };
}

class SongEntry {
  final String title;
  final String artist;

  const SongEntry({required this.title, required this.artist});

  factory SongEntry.fromJson(Map<String, dynamic> json) {
    return SongEntry(
      title: json['title'] as String,
      artist: json['artist'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
      };
}
