
class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserPreferences preferences;
  final UserStats stats;
  final bool isEmailVerified;
  final String? phoneNumber;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    required this.createdAt,
    this.lastLoginAt,
    required this.preferences,
    required this.stats,
    this.isEmailVerified = false,
    this.phoneNumber,
    this.role = UserRole.student,
  });

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return email.split('@').first; // Use email prefix as fallback
    }
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0].toUpperCase()}${lastName![0].toUpperCase()}';
    } else if (firstName != null && firstName!.isNotEmpty) {
      return firstName![0].toUpperCase();
    } else {
      return email[0].toUpperCase();
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.parse(json['lastLoginAt']) 
          : null,
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      stats: UserStats.fromJson(json['stats'] ?? {}),
      isEmailVerified: json['isEmailVerified'] ?? false,
      phoneNumber: json['phoneNumber'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.student,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences.toJson(),
      'stats': stats.toJson(),
      'isEmailVerified': isEmailVerified,
      'phoneNumber': phoneNumber,
      'role': role.toString().split('.').last,
    };
  }

  User copyWith({
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
    UserStats? stats,
    bool? isEmailVerified,
    String? phoneNumber,
    UserRole? role,
  }) {
    return User(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, email: $email, displayName: $displayName}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum UserRole {
  student,    // Étudiant/candidat
  teacher,    // Formateur
  admin,      // Administrateur
}

class UserPreferences {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final String language;
  final String theme; // light, dark, auto
  final bool soundEnabled;
  final int defaultTestDuration; // minutes
  final String preferredDifficulty; // facile, moyen, difficile, adaptatif
  final List<String> favoriteCategories;
  final bool autoSaveProgress;
  final bool showExplanations;

  UserPreferences({
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.language = 'fr',
    this.theme = 'auto',
    this.soundEnabled = true,
    this.defaultTestDuration = 30,
    this.preferredDifficulty = 'adaptatif',
    this.favoriteCategories = const [],
    this.autoSaveProgress = true,
    this.showExplanations = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      language: json['language'] ?? 'fr',
      theme: json['theme'] ?? 'auto',
      soundEnabled: json['soundEnabled'] ?? true,
      defaultTestDuration: json['defaultTestDuration'] ?? 30,
      preferredDifficulty: json['preferredDifficulty'] ?? 'adaptatif',
      favoriteCategories: List<String>.from(json['favoriteCategories'] ?? []),
      autoSaveProgress: json['autoSaveProgress'] ?? true,
      showExplanations: json['showExplanations'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'language': language,
      'theme': theme,
      'soundEnabled': soundEnabled,
      'defaultTestDuration': defaultTestDuration,
      'preferredDifficulty': preferredDifficulty,
      'favoriteCategories': favoriteCategories,
      'autoSaveProgress': autoSaveProgress,
      'showExplanations': showExplanations,
    };
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    String? language,
    String? theme,
    bool? soundEnabled,
    int? defaultTestDuration,
    String? preferredDifficulty,
    List<String>? favoriteCategories,
    bool? autoSaveProgress,
    bool? showExplanations,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      defaultTestDuration: defaultTestDuration ?? this.defaultTestDuration,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      autoSaveProgress: autoSaveProgress ?? this.autoSaveProgress,
      showExplanations: showExplanations ?? this.showExplanations,
    );
  }
}

class UserStats {
  final int testsCompleted;
  final int totalQuestions;
  final int correctAnswers;
  final double averageScore;
  final double bestScore;
  final Duration totalStudyTime;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastTestDate;
  final Map<String, CategoryStats> categoryStats;
  final List<double> recentScores; // Last 10 scores
  final int level;
  final int experience;

  UserStats({
    this.testsCompleted = 0,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.averageScore = 0.0,
    this.bestScore = 0.0,
    this.totalStudyTime = Duration.zero,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastTestDate,
    this.categoryStats = const {},
    this.recentScores = const [],
    this.level = 1,
    this.experience = 0,
  });

  double get accuracyRate => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
  
  String get levelTitle {
    if (level <= 5) return 'Débutant';
    if (level <= 15) return 'Intermédiaire';
    if (level <= 30) return 'Avancé';
    if (level <= 50) return 'Expert';
    return 'Maître';
  }

  int get experienceToNextLevel {
    return (level * 1000) - (experience % (level * 1000));
  }

  double get progressToNextLevel {
    final currentLevelExp = experience % (level * 1000);
    return currentLevelExp / (level * 1000);
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    final categoryStatsJson = json['categoryStats'] as Map<String, dynamic>? ?? {};
    final categoryStats = <String, CategoryStats>{};
    
    categoryStatsJson.forEach((key, value) {
      categoryStats[key] = CategoryStats.fromJson(value);
    });

    return UserStats(
      testsCompleted: json['testsCompleted'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0.0,
      totalStudyTime: Duration(milliseconds: json['totalStudyTime'] ?? 0),
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastTestDate: json['lastTestDate'] != null 
          ? DateTime.parse(json['lastTestDate']) 
          : null,
      categoryStats: categoryStats,
      recentScores: List<double>.from(
        (json['recentScores'] as List?)?.map((e) => (e as num).toDouble()) ?? []
      ),
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final categoryStatsJson = <String, dynamic>{};
    categoryStats.forEach((key, value) {
      categoryStatsJson[key] = value.toJson();
    });

    return {
      'testsCompleted': testsCompleted,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'totalStudyTime': totalStudyTime.inMilliseconds,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastTestDate': lastTestDate?.toIso8601String(),
      'categoryStats': categoryStatsJson,
      'recentScores': recentScores,
      'level': level,
      'experience': experience,
    };
  }

  UserStats copyWith({
    int? testsCompleted,
    int? totalQuestions,
    int? correctAnswers,
    double? averageScore,
    double? bestScore,
    Duration? totalStudyTime,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastTestDate,
    Map<String, CategoryStats>? categoryStats,
    List<double>? recentScores,
    int? level,
    int? experience,
  }) {
    return UserStats(
      testsCompleted: testsCompleted ?? this.testsCompleted,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      averageScore: averageScore ?? this.averageScore,
      bestScore: bestScore ?? this.bestScore,
      totalStudyTime: totalStudyTime ?? this.totalStudyTime,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastTestDate: lastTestDate ?? this.lastTestDate,
      categoryStats: categoryStats ?? this.categoryStats,
      recentScores: recentScores ?? this.recentScores,
      level: level ?? this.level,
      experience: experience ?? this.experience,
    );
  }
}

class CategoryStats {
  final int questionsAnswered;
  final int correctAnswers;
  final double averageScore;
  final double bestScore;
  final int testsCompleted;
  final DateTime? lastTestDate;

  CategoryStats({
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.averageScore = 0.0,
    this.bestScore = 0.0,
    this.testsCompleted = 0,
    this.lastTestDate,
  });

  double get accuracyRate => questionsAnswered > 0 ? correctAnswers / questionsAnswered : 0.0;

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      questionsAnswered: json['questionsAnswered'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      averageScore: (json['averageScore'] as num?)?.toDouble() ?? 0.0,
      bestScore: (json['bestScore'] as num?)?.toDouble() ?? 0.0,
      testsCompleted: json['testsCompleted'] ?? 0,
      lastTestDate: json['lastTestDate'] != null 
          ? DateTime.parse(json['lastTestDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionsAnswered': questionsAnswered,
      'correctAnswers': correctAnswers,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'testsCompleted': testsCompleted,
      'lastTestDate': lastTestDate?.toIso8601String(),
    };
  }

  CategoryStats copyWith({
    int? questionsAnswered,
    int? correctAnswers,
    double? averageScore,
    double? bestScore,
    int? testsCompleted,
    DateTime? lastTestDate,
  }) {
    return CategoryStats(
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      averageScore: averageScore ?? this.averageScore,
      bestScore: bestScore ?? this.bestScore,
      testsCompleted: testsCompleted ?? this.testsCompleted,
      lastTestDate: lastTestDate ?? this.lastTestDate,
    );
  }
}
