#!/bin/bash

# ===========================================
# PSYCHOTEST+ - INSTALLATION USB RAPIDE
# ===========================================
# Script pour installer rapidement l'APK via USB
# Avec désinstallation automatique de l'ancienne version

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
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

print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

# ===========================================
# CONFIGURATION
# ===========================================

APP_PACKAGE="com.psychotest.plus"
APP_MAIN_ACTIVITY="com.psychotest.plus.MainActivity"

print_header "PSYCHOTEST+ - INSTALLATION USB RAPIDE"

# ===========================================
# CONFIGURER FLUTTER PATH
# ===========================================

print_info "Configuration de Flutter..."

# Ajouter Flutter au PATH
export PATH="$PATH:$HOME/flutter/bin"

# Vérifier que Flutter est accessible
if ! command -v flutter &> /dev/null; then
    print_warning "Flutter n'est pas dans le PATH, recherche automatique..."

    # Chercher Flutter dans les emplacements courants
    FLUTTER_PATHS=(
        "$HOME/flutter/bin/flutter"
        "$HOME/development/flutter/bin/flutter"
        "$HOME/snap/flutter/common/flutter/bin/flutter"
        "/usr/local/bin/flutter"
        "/opt/flutter/bin/flutter"
        "$HOME/Android/flutter/bin/flutter"
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
        print_error "Flutter non trouvé. Veuillez l'installer ou ajouter au PATH"
        exit 1
    fi
fi

print_success "Flutter configuré: $(flutter --version | head -n1)"

# ===========================================
# VÉRIFIER LES APPAREILS
# ===========================================

print_info "Recherche d'appareils connectés..."

DEVICES_CHECK=0
MAX_RETRIES=3

while [ $DEVICES_CHECK -lt $MAX_RETRIES ]; do
    DEVICES_OUTPUT=$(flutter devices 2>/dev/null || echo "Erreur")

    if echo "$DEVICES_OUTPUT" | grep -q "No devices detected\|Erreur"; then
        DEVICES_CHECK=$((DEVICES_CHECK + 1))
        if [ $DEVICES_CHECK -lt $MAX_RETRIES ]; then
            print_warning "Aucun appareil détecté (tentative $DEVICES_CHECK/$MAX_RETRIES)"
            print_info "Assurez-vous que:"
            echo "  • Votre téléphone est connecté via USB"
            echo "  • Le débogage USB est activé"
            echo "  • Les pilotes USB sont installés"
            echo ""
            read -p "Connectez votre appareil et appuyez sur Entrée (ou Ctrl+C pour annuler)..."
            echo ""
        else
            print_error "Impossible de détecter un appareil après $MAX_RETRIES tentatives"
            print_info "Vérifiez votre connexion USB et les paramètres développeur"
            exit 1
        fi
    else
        print_success "Appareil(s) détecté(s) !"
        echo "$DEVICES_OUTPUT"
        break
    fi
done

# ===========================================
# DÉSINSTALLATION AUTOMATIQUE
# ===========================================

print_info "Vérification de l'ancienne version..."

# Vérifier si ADB est disponible
if command -v adb &> /dev/null; then
    # Vérifier si l'app est déjà installée
    if adb shell pm list packages | grep -q "$APP_PACKAGE"; then
        print_warning "Ancienne version détectée"

        echo ""
        read -p "Désinstaller automatiquement l'ancienne version? (Y/n): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Désinstallation ignorée"
        else
            print_info "Désinstallation en cours..."

            if adb uninstall "$APP_PACKAGE" 2>/dev/null; then
                print_success "Ancienne version désinstallée !"
            else
                print_warning "Échec de la désinstallation (pas grave)"
            fi
        fi
    else
        print_success "Aucune ancienne version détectée"
    fi
else
    print_warning "ADB non disponible - désinstallation manuelle si nécessaire"
fi

# ===========================================
# BUILD RAPIDE (SI NÉCESSAIRE)
# ===========================================

APK_PATH=""

# Chercher un APK existant
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    print_success "APK debug trouvé"
elif [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    print_success "APK release trouvé"
else
    # Chercher des APK avec timestamp
    LATEST_APK=$(find build/app/outputs/flutter-apk/ -name "*.apk" -type f 2>/dev/null | head -n1)
    if [ -n "$LATEST_APK" ]; then
        APK_PATH="$LATEST_APK"
        print_success "APK trouvé: $(basename $APK_PATH)"
    fi
fi

# Si aucun APK trouvé, construire
if [ -z "$APK_PATH" ]; then
    print_warning "Aucun APK trouvé, build en cours..."

    echo ""
    read -p "Construire en mode debug (plus rapide)? (Y/n): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Build release en cours (plus lent mais optimisé)..."
        flutter build apk --release
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    else
        print_info "Build debug en cours..."
        flutter build apk --debug
        APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    fi

    if [ $? -eq 0 ]; then
        print_success "Build terminé !"
    else
        print_error "Échec du build"
        exit 1
    fi
fi

# ===========================================
# INSTALLATION
# ===========================================

print_header "INSTALLATION"

if [ ! -f "$APK_PATH" ]; then
    print_error "APK non trouvé: $APK_PATH"
    exit 1
fi

# Afficher les infos de l'APK
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
print_info "APK: $(basename $APK_PATH) ($APK_SIZE)"

print_info "Installation en cours..."

# Essayer flutter install d'abord
INSTALL_SUCCESS=false

if flutter install 2>/dev/null; then
    print_success "Installation réussie via Flutter !"
    INSTALL_SUCCESS=true
else
    print_warning "Flutter install échoué, tentative via ADB..."

    # Essayer avec ADB
    if command -v adb &> /dev/null; then
        if adb install -r "$APK_PATH"; then
            print_success "Installation réussie via ADB !"
            INSTALL_SUCCESS=true
        else
            print_error "Échec installation via ADB"
        fi
    else
        print_error "ADB non disponible"
    fi
fi

# ===========================================
# VÉRIFICATION ET LANCEMENT
# ===========================================

if [ "$INSTALL_SUCCESS" = true ]; then
    print_header "SUCCÈS !"

    # Vérifier l'installation
    if command -v adb &> /dev/null; then
        if adb shell pm list packages | grep -q "$APP_PACKAGE"; then
            print_success "✅ PsychoTest+ correctement installé !"

            # Proposer de lancer l'app
            echo ""
            read -p "Lancer l'application maintenant? (Y/n): " -n 1 -r
            echo

            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                print_info "Lancement de PsychoTest+..."

                if adb shell am start -n "$APP_MAIN_ACTIVITY" 2>/dev/null; then
                    print_success "🚀 Application lancée !"
                else
                    print_warning "Impossible de lancer automatiquement"
                    print_info "Lancez manuellement l'app depuis votre téléphone"
                fi
            fi
        else
            print_warning "Installation non confirmée"
        fi
    fi

    echo ""
    print_success "🎉 Installation terminée !"
    print_info "PsychoTest+ est maintenant sur votre téléphone"

else
    print_error "❌ Échec de l'installation automatique"
    echo ""
    print_info "Installation manuelle requise:"
    echo "  1. Copiez: $APK_PATH"
    echo "  2. Transférez sur votre téléphone"
    echo "  3. Installez depuis le gestionnaire de fichiers"
    echo "  4. Autorisez les sources inconnues si demandé"
fi

# ===========================================
# INFORMATIONS UTILES
# ===========================================

echo ""
print_info "📱 Informations utiles:"
echo "  • Package: $APP_PACKAGE"
echo "  • APK: $APK_PATH"
echo "  • Taille: $APK_SIZE"

if command -v adb &> /dev/null; then
    echo ""
    print_info "🔧 Commandes utiles:"
    echo "  • Désinstaller: adb uninstall $APP_PACKAGE"
    echo "  • Lancer: adb shell am start -n $APP_MAIN_ACTIVITY"
    echo "  • Logs: adb logcat | grep Flutter"
fi

echo ""
print_info "🎯 Pour une nouvelle installation, relancez ce script !"
