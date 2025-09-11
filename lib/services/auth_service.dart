import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Service d'authentification complet pour DouaneTest Pro
/// Gère l'inscription, connexion, vérification email, récupération de mot de passe
/// et la persistance de session utilisateur
class AuthService extends ChangeNotifier {
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _authTokenKey = 'auth_token';
  static const String _usersDbKey = 'users_database';
  static const String _verificationCodesKey = 'verification_codes';
  static const String _resetCodesKey = 'reset_codes';
  
  User? _currentUser;
  bool _isLoggedIn = false;
  String? _authToken;
  
  // Mock database pour le développement (remplacé par une vraie API plus tard)
  Map<String, Map<String, dynamic>> _usersDatabase = {};
  Map<String, String> _verificationCodes = {}; // email -> code
  Map<String, String> _resetCodes = {}; // email -> code
  
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String? get authToken => _authToken;
  
  /// Initialise le service d'authentification
  /// Récupère les données persistées et vérifie la session existante
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger la base de données mockée
    final usersJson = prefs.getString(_usersDbKey);
    if (usersJson != null) {
      final Map<String, dynamic> decoded = json.decode(usersJson);
      _usersDatabase = decoded.map((key, value) => 
        MapEntry(key, Map<String, dynamic>.from(value)));
    }
    
    // Charger les codes de vérification
    final verificationJson = prefs.getString(_verificationCodesKey);
    if (verificationJson != null) {
      _verificationCodes = Map<String, String>.from(json.decode(verificationJson));
    }
    
    final resetJson = prefs.getString(_resetCodesKey);
    if (resetJson != null) {
      _resetCodes = Map<String, String>.from(json.decode(resetJson));
    }
    
    // Récupérer la session existante
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    _authToken = prefs.getString(_authTokenKey);
    
    if (_isLoggedIn) {
      final userJson = prefs.getString(_currentUserKey);
      if (userJson != null) {
        try {
          final userData = json.decode(userJson);
          _currentUser = User.fromJson(userData);
          
          // Mettre à jour lastLoginAt
          final now = DateTime.now();
          _currentUser = _currentUser!.copyWith(lastLoginAt: now);
          await _saveCurrentUser();
          
          notifyListeners();
        } catch (e) {
          debugPrint('Erreur lors du chargement de l\'utilisateur: $e');
          await logout();
        }
      }
    }
  }
  
  /// Inscription d'un nouveau utilisateur
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
  }) async {
    try {
      email = email.toLowerCase().trim();
      
      // Validation des données
      if (!_isValidEmail(email)) {
        return AuthResult.error('Format d\'email invalide');
      }
      
      if (password.length < 6) {
        return AuthResult.error('Le mot de passe doit contenir au moins 6 caractères');
      }
      
      // Vérifier si l'utilisateur existe déjà
      if (_usersDatabase.containsKey(email)) {
        return AuthResult.error('Un compte avec cet email existe déjà');
      }
      
      // Créer l'utilisateur
      final userId = _generateUserId();
      final now = DateTime.now();
      
      final user = User(
        id: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        createdAt: now,
        preferences: UserPreferences(),
        stats: UserStats(),
        isEmailVerified: false,
        role: UserRole.student,
      );
      
      // Stocker l'utilisateur avec le mot de passe hashé
      _usersDatabase[email] = {
        ...user.toJson(),
        'password': _hashPassword(password),
      };
      
      await _saveUsersDatabase();
      
      // Générer et envoyer le code de vérification
      final verificationCode = _generateVerificationCode();
      _verificationCodes[email] = verificationCode;
      await _saveVerificationCodes();
      
      // Simuler l'envoi d'email (en production, appeler un service d'email)
      await _sendVerificationEmail(email, verificationCode);
      
      return AuthResult.success(
        user: user,
        message: 'Inscription réussie. Veuillez vérifier votre email.'
      );
      
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      return AuthResult.error('Erreur lors de l\'inscription: $e');
    }
  }
  
  /// Connexion d'un utilisateur existant
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      email = email.toLowerCase().trim();
      
      // Vérifier si l'utilisateur existe
      final userData = _usersDatabase[email];
      if (userData == null) {
        return AuthResult.error('Email ou mot de passe incorrect');
      }
      
      // Vérifier le mot de passe
      if (!_verifyPassword(password, userData['password'])) {
        return AuthResult.error('Email ou mot de passe incorrect');
      }
      
      // Créer l'objet utilisateur
      final user = User.fromJson(userData);
      
      // Vérifier si l'email est vérifié
      if (!user.isEmailVerified) {
        return AuthResult.error(
          'Veuillez vérifier votre email avant de vous connecter. '
          'Utilisez "Renvoyer le code de vérification" si nécessaire.'
        );
      }
      
      // Mettre à jour la dernière connexion
      final now = DateTime.now();
      final updatedUser = user.copyWith(lastLoginAt: now);
      
      _usersDatabase[email] = {
        ...updatedUser.toJson(),
        'password': userData['password'], // Garder le mot de passe hashé
      };
      
      await _saveUsersDatabase();
      
      // Créer la session
      _currentUser = updatedUser;
      _isLoggedIn = true;
      _authToken = _generateAuthToken();
      
      await _saveCurrentUser();
      await _saveSession();
      
      notifyListeners();
      
      return AuthResult.success(
        user: updatedUser,
        message: 'Connexion réussie'
      );
      
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      return AuthResult.error('Erreur lors de la connexion: $e');
    }
  }
  
  /// Vérification de l'email avec le code reçu
  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      email = email.toLowerCase().trim();
      
      // Vérifier le code
      final expectedCode = _verificationCodes[email];
      if (expectedCode == null || expectedCode != code) {
        return AuthResult.error('Code de vérification invalide ou expiré');
      }
      
      // Récupérer l'utilisateur
      final userData = _usersDatabase[email];
      if (userData == null) {
        return AuthResult.error('Utilisateur non trouvé');
      }
      
      // Marquer l'email comme vérifié
      userData['isEmailVerified'] = true;
      _usersDatabase[email] = userData;
      
      // Supprimer le code de vérification
      _verificationCodes.remove(email);
      
      await _saveUsersDatabase();
      await _saveVerificationCodes();
      
      // Si l'utilisateur est actuellement connecté, mettre à jour
      if (_currentUser?.email == email) {
        _currentUser = _currentUser!.copyWith(isEmailVerified: true);
        await _saveCurrentUser();
        notifyListeners();
      }
      
      return AuthResult.success(
        message: 'Email vérifié avec succès. Vous pouvez maintenant vous connecter.'
      );
      
    } catch (e) {
      debugPrint('Erreur lors de la vérification: $e');
      return AuthResult.error('Erreur lors de la vérification: $e');
    }
  }
  
  /// Renvoie un nouveau code de vérification
  Future<AuthResult> resendVerificationCode(String email) async {
    try {
      email = email.toLowerCase().trim();
      
      // Vérifier si l'utilisateur existe
      final userData = _usersDatabase[email];
      if (userData == null) {
        return AuthResult.error('Aucun compte trouvé avec cet email');
      }
      
      // Vérifier si l'email n'est pas déjà vérifié
      if (userData['isEmailVerified'] == true) {
        return AuthResult.error('Cet email est déjà vérifié');
      }
      
      // Générer un nouveau code
      final verificationCode = _generateVerificationCode();
      _verificationCodes[email] = verificationCode;
      await _saveVerificationCodes();
      
      // Envoyer l'email
      await _sendVerificationEmail(email, verificationCode);
      
      return AuthResult.success(
        message: 'Nouveau code de vérification envoyé à votre email'
      );
      
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi: $e');
      return AuthResult.error('Erreur lors de l\'envoi du code');
    }
  }
  
  /// Initie la récupération de mot de passe
  Future<AuthResult> requestPasswordReset(String email) async {
    try {
      email = email.toLowerCase().trim();
      
      // Vérifier si l'utilisateur existe
      final userData = _usersDatabase[email];
      if (userData == null) {
        // Pour la sécurité, on ne révèle pas si l'email existe ou non
        return AuthResult.success(
          message: 'Si un compte existe avec cet email, vous recevrez un code de réinitialisation'
        );
      }
      
      // Générer le code de réinitialisation
      final resetCode = _generateVerificationCode();
      _resetCodes[email] = resetCode;
      await _saveResetCodes();
      
      // Envoyer l'email avec le code
      await _sendPasswordResetEmail(email, resetCode);
      
      return AuthResult.success(
        message: 'Si un compte existe avec cet email, vous recevrez un code de réinitialisation'
      );
      
    } catch (e) {
      debugPrint('Erreur lors de la demande de réinitialisation: $e');
      return AuthResult.error('Erreur lors de la demande de réinitialisation');
    }
  }
  
  /// Réinitialise le mot de passe avec le code reçu
  Future<AuthResult> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      email = email.toLowerCase().trim();
      
      // Vérifier le code
      final expectedCode = _resetCodes[email];
      if (expectedCode == null || expectedCode != code) {
        return AuthResult.error('Code de réinitialisation invalide ou expiré');
      }
      
      // Validation du nouveau mot de passe
      if (newPassword.length < 6) {
        return AuthResult.error('Le nouveau mot de passe doit contenir au moins 6 caractères');
      }
      
      // Récupérer l'utilisateur
      final userData = _usersDatabase[email];
      if (userData == null) {
        return AuthResult.error('Utilisateur non trouvé');
      }
      
      // Mettre à jour le mot de passe
      userData['password'] = _hashPassword(newPassword);
      _usersDatabase[email] = userData;
      
      // Supprimer le code de réinitialisation
      _resetCodes.remove(email);
      
      await _saveUsersDatabase();
      await _saveResetCodes();
      
      return AuthResult.success(
        message: 'Mot de passe réinitialisé avec succès. Vous pouvez maintenant vous connecter.'
      );
      
    } catch (e) {
      debugPrint('Erreur lors de la réinitialisation: $e');
      return AuthResult.error('Erreur lors de la réinitialisation du mot de passe');
    }
  }
  
  /// Met à jour le profil de l'utilisateur connecté
  Future<AuthResult> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
    UserPreferences? preferences,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult.error('Aucun utilisateur connecté');
      }
      
      // Mettre à jour l'utilisateur
      final updatedUser = _currentUser!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
        preferences: preferences,
      );
      
      // Sauvegarder dans la "base de données"
      final userData = _usersDatabase[_currentUser!.email];
      if (userData != null) {
        _usersDatabase[_currentUser!.email] = {
          ...updatedUser.toJson(),
          'password': userData['password'], // Garder le mot de passe
        };
        await _saveUsersDatabase();
      }
      
      // Mettre à jour la session
      _currentUser = updatedUser;
      await _saveCurrentUser();
      
      notifyListeners();
      
      return AuthResult.success(
        user: updatedUser,
        message: 'Profil mis à jour avec succès'
      );
      
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour: $e');
      return AuthResult.error('Erreur lors de la mise à jour du profil');
    }
  }
  
  /// Met à jour les statistiques de l'utilisateur
  Future<void> updateUserStats(UserStats newStats) async {
    if (_currentUser == null) return;
    
    try {
      final updatedUser = _currentUser!.copyWith(stats: newStats);
      
      // Sauvegarder dans la "base de données"
      final userData = _usersDatabase[_currentUser!.email];
      if (userData != null) {
        _usersDatabase[_currentUser!.email] = {
          ...updatedUser.toJson(),
          'password': userData['password'], // Garder le mot de passe
        };
        await _saveUsersDatabase();
      }
      
      // Mettre à jour la session
      _currentUser = updatedUser;
      await _saveCurrentUser();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des stats: $e');
    }
  }
  
  /// Déconnexion de l'utilisateur
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Supprimer les données de session
      await prefs.remove(_currentUserKey);
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_authTokenKey);
      
      // Réinitialiser les variables
      _currentUser = null;
      _isLoggedIn = false;
      _authToken = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }
  
  // Méthodes privées pour la persistance
  
  Future<void> _saveCurrentUser() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(_currentUser!.toJson());
      await prefs.setString(_currentUserKey, userJson);
    }
  }
  
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, _isLoggedIn);
    if (_authToken != null) {
      await prefs.setString(_authTokenKey, _authToken!);
    }
  }
  
  Future<void> _saveUsersDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final dbJson = json.encode(_usersDatabase);
    await prefs.setString(_usersDbKey, dbJson);
  }
  
  Future<void> _saveVerificationCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codesJson = json.encode(_verificationCodes);
    await prefs.setString(_verificationCodesKey, codesJson);
  }
  
  Future<void> _saveResetCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codesJson = json.encode(_resetCodes);
    await prefs.setString(_resetCodesKey, codesJson);
  }
  
  // Méthodes utilitaires
  
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
  
  String _generateAuthToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // Code à 6 chiffres
  }
  
  String _hashPassword(String password) {
    // En production, utiliser bcrypt ou similar
    // Pour le développement, un hash simple suffira
    return password.split('').reversed.join() + '_hashed';
  }
  
  bool _verifyPassword(String password, String hashedPassword) {
    return _hashPassword(password) == hashedPassword;
  }
  
  Future<void> _sendVerificationEmail(String email, String code) async {
    // Simulation de l'envoi d'email
    // En production, utiliser un service comme SendGrid, AWS SES, etc.
    debugPrint('📧 Email de vérification envoyé à $email avec le code: $code');
    
    // Simuler un délai d'envoi
    await Future.delayed(Duration(seconds: 1));
  }
  
  Future<void> _sendPasswordResetEmail(String email, String code) async {
    // Simulation de l'envoi d'email pour la réinitialisation
    debugPrint('🔐 Email de réinitialisation envoyé à $email avec le code: $code');
    
    // Simuler un délai d'envoi
    await Future.delayed(Duration(seconds: 1));
  }
  
  /// Méthodes de débogage (à supprimer en production)
  
  void printVerificationCode(String email) {
    final code = _verificationCodes[email.toLowerCase().trim()];
    debugPrint('🔍 Code de vérification pour $email: $code');
  }
  
  void printResetCode(String email) {
    final code = _resetCodes[email.toLowerCase().trim()];
    debugPrint('🔍 Code de réinitialisation pour $email: $code');
  }
  
  Map<String, String> getAllVerificationCodes() {
    return Map.from(_verificationCodes);
  }
  
  Map<String, String> getAllResetCodes() {
    return Map.from(_resetCodes);
  }
}

/// Résultat d'une opération d'authentification
class AuthResult {
  final bool isSuccess;
  final String message;
  final User? user;
  final String? errorCode;
  
  AuthResult._({
    required this.isSuccess,
    required this.message,
    this.user,
    this.errorCode,
  });
  
  factory AuthResult.success({
    User? user,
    String message = 'Opération réussie',
  }) {
    return AuthResult._(
      isSuccess: true,
      message: message,
      user: user,
    );
  }
  
  factory AuthResult.error(String message, [String? errorCode]) {
    return AuthResult._(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }
  
  @override
  String toString() {
    return 'AuthResult{isSuccess: $isSuccess, message: $message, user: $user}';
  }
}
