import 'question.dart';

/// Model representing a complete test with metadata and questions
class TestModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final int duration; // in minutes
  final int totalQuestions;
  final List<Question> questions;
  final String difficulty; // 'facile', 'moyen', 'difficile'
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  TestModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.duration,
    required this.totalQuestions,
    required this.questions,
    this.difficulty = 'moyen',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.imageUrl,
    this.metadata,
  });

  /// Create TestModel from JSON
  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      duration: json['duration'] ?? 30,
      totalQuestions: json['totalQuestions'] ?? 0,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => Question.fromJson(q as Map<String, dynamic>))
          .toList() ?? [],
      difficulty: json['difficulty'] ?? 'moyen',
      tags: (json['tags'] as List<dynamic>?)
          ?.map((tag) => tag.toString())
          .toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      imageUrl: json['imageUrl'],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert TestModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'duration': duration,
      'totalQuestions': totalQuestions,
      'questions': questions.map((q) => q.toJson()).toList(),
      'difficulty': difficulty,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  /// Create a copy of this TestModel with some fields replaced
  TestModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? duration,
    int? totalQuestions,
    List<Question>? questions,
    String? difficulty,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return TestModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      questions: questions ?? this.questions,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get difficulty color for UI
  String get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return '#4CAF50'; // Green
      case 'difficile':
        return '#F44336'; // Red
      case 'moyen':
      default:
        return '#FF9800'; // Orange
    }
  }

  /// Get estimated completion time in minutes
  int get estimatedTime {
    return duration;
  }

  /// Get completion percentage based on answered questions
  double getCompletionPercentage(int answeredQuestions) {
    if (totalQuestions == 0) return 0.0;
    return (answeredQuestions / totalQuestions * 100).clamp(0.0, 100.0);
  }

  /// Check if test is available (active and has questions)
  bool get isAvailable {
    return isActive && questions.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TestModel(id: $id, title: $title, category: $category, totalQuestions: $totalQuestions)';
  }
}
