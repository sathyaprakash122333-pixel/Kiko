/// Domain model representing an authenticated user's profile from FastAPI
class UserProfile {
  final int id;
  final int? userId;
  final String firebaseUid;
  final String? email;
  final String? fullName;
  final String? displayName;
  final String? dateOfBirth;
  final String? gender;
  final String? city;
  final String? institution;
  final String? degree;
  final String? department;
  final String? academicYear;
  final String? semester;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  const UserProfile({
    required this.id,
    this.userId,
    required this.firebaseUid,
    this.email,
    this.fullName,
    this.displayName,
    this.dateOfBirth,
    this.gender,
    this.city,
    this.institution,
    this.degree,
    this.department,
    this.academicYear,
    this.semester,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  /// Genuine user display name (returns null if unprovided, avoiding fabricated defaults)
  String? get effectiveNameOrNull {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      final trimmed = fullName!.trim();
      if (trimmed.toLowerCase() != 'programmer') {
        return trimmed;
      }
    }
    if (displayName != null && displayName!.trim().isNotEmpty) {
      final trimmed = displayName!.trim();
      if (trimmed.toLowerCase() != 'programmer') {
        return trimmed;
      }
    }
    return null;
  }

  /// Effective user display name with fallback for friendly greeting
  String get effectiveName {
    return effectiveNameOrNull ?? 'Learner';
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      displayName: json['display_name'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      city: json['city'] as String?,
      institution: json['institution'] as String?,
      degree: json['degree'] as String?,
      department: json['department'] as String?,
      academicYear: json['academic_year'] as String?,
      semester: json['semester'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'firebase_uid': firebaseUid,
      'email': email,
      'full_name': fullName,
      'display_name': displayName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'city': city,
      'institution': institution,
      'degree': degree,
      'department': department,
      'academic_year': academicYear,
      'semester': semester,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    int? userId,
    String? firebaseUid,
    String? email,
    String? fullName,
    String? displayName,
    String? dateOfBirth,
    String? gender,
    String? city,
    String? institution,
    String? degree,
    String? department,
    String? academicYear,
    String? semester,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}

/// Domain model representing a user's persistent learning streak
class UserStreak {
  final int currentStreak;
  final int longestStreak;
  final String? lastActivityDate;
  final bool activeToday;
  final int totalActiveDays;
  final List<String> recentActiveDates;

  const UserStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
    required this.activeToday,
    required this.totalActiveDays,
    this.recentActiveDates = const [],
  });

  factory UserStreak.empty() {
    return const UserStreak(
      currentStreak: 0,
      longestStreak: 0,
      lastActivityDate: null,
      activeToday: false,
      totalActiveDays: 0,
      recentActiveDates: [],
    );
  }

  factory UserStreak.fromJson(Map<String, dynamic> json) {
    return UserStreak(
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      lastActivityDate: json['last_activity_date'] as String?,
      activeToday: json['active_today'] as bool? ?? false,
      totalActiveDays: (json['total_active_days'] as num?)?.toInt() ?? 0,
      recentActiveDates: (json['recent_active_dates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_activity_date': lastActivityDate,
      'active_today': activeToday,
      'total_active_days': totalActiveDays,
      'recent_active_dates': recentActiveDates,
    };
  }
}
