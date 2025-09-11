/// Modèle pour représenter une transaction de paiement
class PaymentTransaction {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final String phoneNumber;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = 'CFA',
    required this.paymentMethod,
    required this.phoneNumber,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.metadata,
  });

  /// Convertit depuis JSON
  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'CFA',
      paymentMethod: json['paymentMethod'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      status: PaymentStatus.values.firstWhere(
        (status) => status.toString().split('.').last == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      errorMessage: json['errorMessage'],
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }

  /// Convertit vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'phoneNumber': phoneNumber,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  /// Crée une copie avec des valeurs modifiées
  PaymentTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? phoneNumber,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'PaymentTransaction(id: $id, amount: $amount, status: $status, method: $paymentMethod)';
  }
}

/// État d'un paiement
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

/// Extension pour obtenir des labels lisibles des statuts de paiement
extension PaymentStatusExtension on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.processing:
        return 'Traitement en cours';
      case PaymentStatus.completed:
        return 'Terminé';
      case PaymentStatus.failed:
        return 'Échec';
      case PaymentStatus.cancelled:
        return 'Annulé';
      case PaymentStatus.refunded:
        return 'Remboursé';
    }
  }

  bool get isCompleted => this == PaymentStatus.completed;
  bool get isFailed => this == PaymentStatus.failed || this == PaymentStatus.cancelled;
  bool get isPending => this == PaymentStatus.pending || this == PaymentStatus.processing;
}

/// Modèle pour représenter l'état d'abonnement d'un utilisateur
class SubscriptionStatus {
  final String userId;
  final bool isPremium;
  final SubscriptionType subscriptionType;
  final DateTime? subscriptionDate;
  final DateTime? expirationDate;
  final String? transactionId;
  final String? paymentMethod;
  final int freeTestsUsed;
  final int freeTestsRemaining;

  SubscriptionStatus({
    required this.userId,
    this.isPremium = false,
    this.subscriptionType = SubscriptionType.free,
    this.subscriptionDate,
    this.expirationDate,
    this.transactionId,
    this.paymentMethod,
    this.freeTestsUsed = 0,
    this.freeTestsRemaining = 3,
  });

  /// Convertit depuis JSON
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      userId: json['userId'] ?? '',
      isPremium: json['isPremium'] ?? false,
      subscriptionType: SubscriptionType.values.firstWhere(
        (type) => type.toString().split('.').last == json['subscriptionType'],
        orElse: () => SubscriptionType.free,
      ),
      subscriptionDate: json['subscriptionDate'] != null 
          ? DateTime.parse(json['subscriptionDate']) 
          : null,
      expirationDate: json['expirationDate'] != null 
          ? DateTime.parse(json['expirationDate']) 
          : null,
      transactionId: json['transactionId'],
      paymentMethod: json['paymentMethod'],
      freeTestsUsed: json['freeTestsUsed'] ?? 0,
      freeTestsRemaining: json['freeTestsRemaining'] ?? 3,
    );
  }

  /// Convertit vers JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isPremium': isPremium,
      'subscriptionType': subscriptionType.toString().split('.').last,
      'subscriptionDate': subscriptionDate?.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'freeTestsUsed': freeTestsUsed,
      'freeTestsRemaining': freeTestsRemaining,
    };
  }

  /// Crée une copie avec des valeurs modifiées
  SubscriptionStatus copyWith({
    String? userId,
    bool? isPremium,
    SubscriptionType? subscriptionType,
    DateTime? subscriptionDate,
    DateTime? expirationDate,
    String? transactionId,
    String? paymentMethod,
    int? freeTestsUsed,
    int? freeTestsRemaining,
  }) {
    return SubscriptionStatus(
      userId: userId ?? this.userId,
      isPremium: isPremium ?? this.isPremium,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionDate: subscriptionDate ?? this.subscriptionDate,
      expirationDate: expirationDate ?? this.expirationDate,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      freeTestsUsed: freeTestsUsed ?? this.freeTestsUsed,
      freeTestsRemaining: freeTestsRemaining ?? this.freeTestsRemaining,
    );
  }

  /// Vérifie si l'abonnement est actif
  bool get isActive {
    if (!isPremium) return false;
    if (subscriptionType == SubscriptionType.lifetime) return true;
    if (expirationDate == null) return false;
    return DateTime.now().isBefore(expirationDate!);
  }

  /// Vérifie si l'utilisateur peut prendre un test
  bool get canTakeTest {
    if (isActive) return true;
    return freeTestsRemaining > 0;
  }

  @override
  String toString() {
    return 'SubscriptionStatus(userId: $userId, isPremium: $isPremium, type: $subscriptionType, active: $isActive)';
  }
}

/// Types d'abonnement
enum SubscriptionType {
  free,
  lifetime,
  monthly,
  yearly,
}

/// Extension pour obtenir des labels lisibles des types d'abonnement
extension SubscriptionTypeExtension on SubscriptionType {
  String get label {
    switch (this) {
      case SubscriptionType.free:
        return 'Gratuit';
      case SubscriptionType.lifetime:
        return 'À vie';
      case SubscriptionType.monthly:
        return 'Mensuel';
      case SubscriptionType.yearly:
        return 'Annuel';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionType.free:
        return '3 tests gratuits';
      case SubscriptionType.lifetime:
        return 'Accès illimité à vie';
      case SubscriptionType.monthly:
        return 'Accès illimité pendant 1 mois';
      case SubscriptionType.yearly:
        return 'Accès illimité pendant 1 an';
    }
  }
}

/// Modèle pour les méthodes de paiement mobile money
class MobileMoneyProvider {
  final String id;
  final String name;
  final String displayName;
  final String iconPath;
  final int color;
  final String instructions;
  final bool isAvailable;
  final List<String> supportedPrefixes;

  MobileMoneyProvider({
    required this.id,
    required this.name,
    required this.displayName,
    required this.iconPath,
    required this.color,
    required this.instructions,
    this.isAvailable = true,
    required this.supportedPrefixes,
  });

  /// Convertit depuis JSON
  factory MobileMoneyProvider.fromJson(Map<String, dynamic> json) {
    return MobileMoneyProvider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      iconPath: json['iconPath'] ?? '',
      color: json['color'] ?? 0xFF000000,
      instructions: json['instructions'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      supportedPrefixes: List<String>.from(json['supportedPrefixes'] ?? []),
    );
  }

  /// Convertit vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'iconPath': iconPath,
      'color': color,
      'instructions': instructions,
      'isAvailable': isAvailable,
      'supportedPrefixes': supportedPrefixes,
    };
  }

  /// Vérifie si un numéro de téléphone est compatible avec ce provider
  bool supportsPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    return supportedPrefixes.any((prefix) => cleaned.startsWith(prefix));
  }

  @override
  String toString() {
    return 'MobileMoneyProvider(id: $id, name: $name, available: $isAvailable)';
  }
}

/// Modèle pour une demande de paiement
class PaymentRequest {
  final String phoneNumber;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String description;
  final Map<String, dynamic>? metadata;

  PaymentRequest({
    required this.phoneNumber,
    required this.paymentMethod,
    required this.amount,
    this.currency = 'CFA',
    this.description = 'DouaneTest Pro - Accès Premium',
    this.metadata,
  });

  /// Convertit depuis JSON
  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      phoneNumber: json['phoneNumber'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'CFA',
      description: json['description'] ?? 'DouaneTest Pro - Accès Premium',
      metadata: json['metadata']?.cast<String, dynamic>(),
    );
  }

  /// Convertit vers JSON
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'currency': currency,
      'description': description,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'PaymentRequest(phone: $phoneNumber, method: $paymentMethod, amount: $amount)';
  }
}
