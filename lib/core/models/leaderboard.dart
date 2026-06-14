class LeaderboardRow {
  final String id;
  final String name;
  final int rank;
  final int value;
  final bool isMe;
  final bool hasName;

  LeaderboardRow({
    required this.id,
    required this.name,
    required this.rank,
    required this.value,
    required this.isMe,
    required this.hasName,
  });

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) {
    return LeaderboardRow(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rank: json['rank'] ?? 0,
      value: json['value'] ?? 0,
      isMe: json['isMe'] ?? false,
      hasName: json['hasName'] ?? false,
    );
  }
}

class LeaderboardResponse {
  final String metric;
  final List<LeaderboardRow> rows;
  final LeaderboardRow? me;

  LeaderboardResponse({required this.metric, required this.rows, this.me});

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      metric: json['metric'] ?? 'words',
      rows: (json['rows'] as List? ?? [])
          .map((r) => LeaderboardRow.fromJson(r))
          .toList(),
      me: json['me'] != null ? LeaderboardRow.fromJson(json['me']) : null,
    );
  }
}

class ProfileResponse {
  final String name;
  final bool isMe;
  final KudosInfo kudos;
  final Map<String, int> heatmap;
  final List<VersusMetric> metrics;
  final ProfileAchievements achievements;

  ProfileResponse({
    required this.name,
    required this.isMe,
    required this.kudos,
    required this.heatmap,
    required this.metrics,
    required this.achievements,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      name: json['name'] ?? '',
      isMe: json['isMe'] ?? false,
      kudos: KudosInfo.fromJson(json['kudos'] ?? {}),
      heatmap: Map<String, int>.from(json['heatmap'] ?? {}),
      metrics: (json['metrics'] as List? ?? [])
          .map((m) => VersusMetric.fromJson(m))
          .toList(),
      achievements: ProfileAchievements.fromJson(json['achievements'] ?? {}),
    );
  }
}

class KudosInfo {
  final int count;
  final bool gaveByMe;

  KudosInfo({required this.count, required this.gaveByMe});

  factory KudosInfo.fromJson(Map<String, dynamic> json) {
    return KudosInfo(
      count: json['count'] ?? 0,
      gaveByMe: json['gaveByMe'] ?? false,
    );
  }
}

class VersusMetric {
  final String key;
  final String label;
  final int me;
  final int them;
  final int better;

  VersusMetric({
    required this.key,
    required this.label,
    required this.me,
    required this.them,
    required this.better,
  });

  factory VersusMetric.fromJson(Map<String, dynamic> json) {
    return VersusMetric(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      me: json['me'] ?? 0,
      them: json['them'] ?? 0,
      better: json['better'] ?? 0,
    );
  }
}

class ProfileAchievements {
  final int myTotal;
  final int myUnlocked;
  final int theirTotal;
  final int unlocked;

  ProfileAchievements({
    required this.myTotal,
    required this.myUnlocked,
    required this.theirTotal,
    required this.unlocked,
  });

  factory ProfileAchievements.fromJson(Map<String, dynamic> json) {
    return ProfileAchievements(
      myTotal: json['my_total'] ?? 0,
      myUnlocked: json['my_unlocked'] ?? 0,
      theirTotal: json['their_total'] ?? 0,
      unlocked: json['unlocked'] ?? 0,
    );
  }
}
