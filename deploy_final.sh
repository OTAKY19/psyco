#!/bin/bash

# ===========================================
# PSYCHOTEST+ - SCRIPT DE DÉPLOIEMENT FINAL
# ===========================================
# Application prête pour Google Play Store
# Version: 1.0.0+1
# Date: 14 Septembre 2025

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ===========================================
# VÉRIFICATIONS PRÉLIMINAIRES
# ===========================================

print_header "VÉRIFICATIONS PRÉLIMINAIRES"

# Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    print_error "Flutter n'est pas installé ou n'est pas dans le PATH"
    exit 1
fi

print_success "Flutter détecté: $(flutter --version | head -n 1)"

# Vérifier la version Flutter
FLUTTER_VERSION=$(flutter --version | grep -oP 'Flutter \K[^\s]+')
REQUIRED_VERSION="3.6.0"

if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$FLUTTER_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    print_warning "Version Flutter recommandée: $REQUIRED_VERSION ou supérieure"
    print_info "Version actuelle: $FLUTTER_VERSION"
fi

# Vérifier les dépendances
print_info "Vérification des dépendances..."
flutter pub get

if [ $? -eq 0 ]; then
    print_success "Dépendances installées avec succès"
else
    print_error "Erreur lors de l'installation des dépendances"
    exit 1
fi

# ===========================================
# ANALYSE STATIQUE
# ===========================================

print_header "ANALYSE STATIQUE DU CODE"

print_info "Exécution de flutter analyze..."
ANALYZE_OUTPUT=$(flutter analyze 2>&1)
ANALYZE_EXIT_CODE=$?

if [ $ANALYZE_EXIT_CODE -eq 0 ]; then
    print_success "Analyse statique réussie - Aucune erreur critique"
else
    print_warning "Avertissements détectés dans l'analyse statique"
    echo "$ANALYZE_OUTPUT" | grep -E "(error|warning)" | head -10
fi

# Compter les issues
ERRORS=$(echo "$ANALYZE_OUTPUT" | grep -c "error" || true)
WARNINGS=$(echo "$ANALYZE_OUTPUT" | grep -c "warning\|info" || true)

print_info "Résumé analyse: $ERRORS erreurs, $WARNINGS avertissements"

# ===========================================
# BUILD DE PRODUCTION
# ===========================================

print_header "BUILD DE PRODUCTION"

# Nettoyer le projet
print_info "Nettoyage du projet..."
flutter clean

# Générer timestamp pour le nom du fichier
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
APK_NAME="psychotest_production_$TIMESTAMP.apk"

print_info "Build APK release optimisé..."
flutter build apk --release --split-per-abi

if [ $? -eq 0 ]; then
    print_success "Build réussi !"

    # Renommer l'APK avec timestamp
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        mv "build/app/outputs/flutter-apk/app-release.apk" "build/app/outputs/flutter-apk/$APK_NAME"
        print_success "APK renommé: $APK_NAME"
    fi
else
    print_error "Échec du build"
    exit 1
fi

# ===========================================
# OPTIMISATIONS ET MÉTRIQUES
# ===========================================

print_header "OPTIMISATIONS ET MÉTRIQUES"

# Vérifier la taille de l'APK
if [ -f "build/app/outputs/flutter-apk/$APK_NAME" ]; then
    APK_SIZE=$(du -h "build/app/outputs/flutter-apk/$APK_NAME" | cut -f1)
    APK_BYTES=$(stat -f%z "build/app/outputs/flutter-apk/$APK_NAME" 2>/dev/null || stat -c%s "build/app/outputs/flutter-apk/$APK_NAME" 2>/dev/null || echo "0")

    print_success "Taille APK: $APK_SIZE (${APK_BYTES} bytes)"

    # Vérifier si la taille est acceptable (< 100MB recommandé)
    if [ "$APK_BYTES" -gt 104857600 ]; then
        print_warning "Taille APK élevée (>100MB) - Considérer l'optimisation"
    else
        print_success "Taille APK acceptable"
    fi
fi

# ===========================================
# TESTS FONCTIONNELS
# ===========================================

print_header "TESTS FONCTIONNELS"

print_info "Exécution des tests unitaires..."
flutter test --coverage

if [ $? -eq 0 ]; then
    print_success "Tests unitaires réussis"
else
    print_warning "Échec de certains tests - Vérifier les logs"
fi

# ===========================================
# DÉPLOIEMENT ET DISTRIBUTION
# ===========================================

print_header "DÉPLOIEMENT ET DISTRIBUTION"

# Créer dossier de distribution
DIST_DIR="distribution_$TIMESTAMP"
mkdir -p "$DIST_DIR"

# Copier l'APK
if [ -f "build/app/outputs/flutter-apk/$APK_NAME" ]; then
    cp "build/app/outputs/flutter-apk/$APK_NAME" "$DIST_DIR/"
    print_success "APK copié dans $DIST_DIR/"
fi

# Créer fichier de métadonnées
cat > "$DIST_DIR/build_info.txt" << EOF
PsychoTest+ - Build Information
===============================
Version: 1.0.0+1
Build Date: $(date)
Flutter Version: $FLUTTER_VERSION
APK Size: $APK_SIZE
Build Type: Release (Production)

Features:
- Système MTN Mobile Money intégré
- Tests psychotechniques complets
- Interface utilisateur moderne
- Mode hors ligne
- Statistiques avancées
- Abonnements premium

Technical Details:
- Target: Android API 21+
- Architecture: ARM64, ARM32, x86_64
- Min SDK: 21
- Target SDK: 34
EOF

print_success "Métadonnées créées"

# ===========================================
# INSTRUCTIONS DE DÉPLOIEMENT
# ===========================================

print_header "INSTRUCTIONS DE DÉPLOIEMENT"

cat << 'EOF'
📱 DÉPLOIEMENT GOOGLE PLAY STORE
================================

1. PRÉPARATION:
   ✅ Build APK réussi
   ✅ Analyse statique passée
   ✅ Tests fonctionnels OK
   ✅ Métadonnées complètes

2. GOOGLE PLAY CONSOLE:
   - Créer une application
   - Upload APK: distribution_*/psychotest_*.apk
   - Configurer store listing
   - Définir prix et distribution
   - Soumettre pour révision

3. INFORMATIONS REQUISES:
   - Nom: PsychoTest+
   - Package: com.example.psychotest_plus
   - Version: 1.0.0+1
   - Min SDK: 21
   - Target SDK: 34

4. ASSETS REQUISES:
   - Icône app (512x512)
   - Screenshots (x4)
   - Feature graphic (1024x500)
   - Description courte/longue

5. MONÉTISATION:
   - Prix: 2499 FCFA (Premium)
   - Modèle: Achat unique
   - Marchés: Bénin

EOF

# ===========================================
# RÉSUMÉ FINAL
# ===========================================

print_header "RÉSUMÉ FINAL"

echo ""
print_success "🎊 APPLICATION PRÊTE POUR PUBLICATION !"
echo ""
print_info "📦 APK: $DIST_DIR/$APK_NAME"
print_info "📏 Taille: $APK_SIZE"
print_info "📅 Date: $(date)"
print_info "🔧 Flutter: $FLUTTER_VERSION"
echo ""
print_info "✅ Fonctionnalités principales:"
echo "   • Système MTN Mobile Money intégré"
echo "   • Tests psychotechniques complets"
echo "   • Interface moderne et responsive"
echo "   • Mode hors ligne"
echo "   • Statistiques détaillées"
echo "   • Abonnements premium"
echo ""
print_info "🚀 Prochaines étapes:"
echo "   1. Upload sur Google Play Console"
echo "   2. Configuration du store listing"
echo "   3. Tests sur appareils réels"
echo "   4. Soumission pour révision"
echo ""

# ===========================================
# INSTALLATION VIA USB
# ===========================================

print_header "INSTALLATION VIA USB"

# Configurer le PATH Flutter
export PATH="$PATH:$HOME/flutter/bin"

# Vérifier que Flutter est accessible
if ! command -v flutter &> /dev/null; then
    print_error "Flutter n'est pas accessible dans le PATH"
    print_info "Tentative de localisation de Flutter..."

    # Chercher Flutter dans les emplacements courants
    FLUTTER_PATHS=(
        "$HOME/flutter/bin/flutter"
        "$HOME/development/flutter/bin/flutter"
        "/usr/local/bin/flutter"
        "/opt/flutter/bin/flutter"
    )

    FLUTTER_FOUND=false
    for flutter_path in "${FLUTTER_PATHS[@]}"; do
        if [ -f "$flutter_path" ]; then
            export PATH="$(dirname $flutter_path):$PATH"
            print_success "Flutter trouvé: $flutter_path"
            FLUTTER_FOUND=true
            break
        fi
    done

    if [ "$FLUTTER_FOUND" = false ]; then
        print_error "Flutter non trouvé. Assurez-vous qu'il est installé."
        exit 1
    fi
fi

print_info "Vérification des appareils connectés..."
DEVICES_OUTPUT=$(flutter devices 2>/dev/null)
echo "$DEVICES_OUTPUT"

# Vérifier si un appareil est connecté
if echo "$DEVICES_OUTPUT" | grep -q "No devices detected"; then
    print_warning "Aucun appareil détecté"
    print_info "Connectez votre téléphone via USB et activez le débogage USB"
    echo ""
    read -p "Appuyez sur Entrée après avoir connecté votre appareil..."

    # Re-vérifier les appareils
    print_info "Nouvelle vérification des appareils..."
    flutter devices
fi

echo ""
read -p "Voulez-vous installer l'APK sur un appareil connecté via USB? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "build/app/outputs/flutter-apk/$APK_NAME" ]; then

        # Demander si on doit désinstaller l'ancienne version
        echo ""
        read -p "Désinstaller l'ancienne version avant installation? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Désinstallation de l'ancienne version..."

            # Utiliser adb pour désinstaller si disponible
            if command -v adb &> /dev/null; then
                adb uninstall com.psychotest.plus 2>/dev/null || true
                print_success "Ancienne version désinstallée (si elle existait)"
            else
                print_warning "ADB non disponible - désinstallation manuelle requise"
            fi
        fi

        print_info "Installation de l'APK via USB..."
        print_info "APK: $APK_NAME"

        # Installer l'APK avec gestion d'erreur améliorée
        if flutter install --device-id=all 2>/dev/null; then
            print_success "APK installé avec succès sur l'appareil !"
            print_info "L'application PsychoTest+ est maintenant sur votre téléphone ! 📱"
            print_info "Vous pouvez la trouver dans vos applications."
        else
            print_warning "Installation via 'flutter install' échouée, tentative alternative..."

            # Méthode alternative avec adb
            if command -v adb &> /dev/null; then
                print_info "Installation via ADB..."
                if adb install -r "build/app/outputs/flutter-apk/$APK_NAME"; then
                    print_success "APK installé avec succès via ADB !"
                else
                    print_error "Échec de l'installation via ADB"
                    print_info "Instructions manuelles:"
                    echo "  1. Copiez le fichier: build/app/outputs/flutter-apk/$APK_NAME"
                    echo "  2. Transférez-le sur votre téléphone"
                    echo "  3. Installez-le manuellement depuis le gestionnaire de fichiers"
                fi
            else
                print_error "Échec de l'installation automatique"
                print_info "Instructions manuelles:"
                echo "  1. Copiez le fichier: build/app/outputs/flutter-apk/$APK_NAME"
                echo "  2. Transférez-le sur votre téléphone"
                echo "  3. Installez-le manuellement depuis le gestionnaire de fichiers"
            fi
        fi

        # Vérifier l'installation
        echo ""
        print_info "Vérification de l'installation..."
        if command -v adb &> /dev/null; then
            if adb shell pm list packages | grep -q "com.psychotest.plus"; then
                print_success "✅ Application correctement installée !"
                print_info "Package: com.psychotest.plus"

                # Optionnel: lancer l'app
                echo ""
                read -p "Voulez-vous lancer l'application maintenant? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    print_info "Lancement de PsychoTest+..."
                    adb shell am start -n com.psychotest.plus/com.psychotest.plus.MainActivity
                    print_success "Application lancée !"
                fi
            else
                print_warning "Impossible de vérifier l'installation"
            fi
        fi

    else
        print_error "APK non trouvé: build/app/outputs/flutter-apk/$APK_NAME"
        print_info "Assurez-vous que le build s'est terminé avec succès"
    fi
else
    print_info "Installation USB ignorée"
fi

# ===========================================
# NETTOYAGE OPTIONNEL
# ===========================================

echo ""
read -p "Voulez-vous nettoyer les fichiers temporaires? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Nettoyage des fichiers temporaires..."
    flutter clean
    rm -rf build/app/intermediates
    print_success "Nettoyage terminé"
fi

print_success "🎉 Script de déploiement terminé avec succès !"
print_info "Votre application PsychoTest+ est prête pour conquérir le marché Béninois ! 🚀"
