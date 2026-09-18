#!/bin/bash

# ===========================================
# PSYCHOTEST+ - BUILD RAPIDE POUR TESTS
# ===========================================
# Script simplifié pour les tests quotidiens avec transfert automatique

# Couleurs pour les logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}🚀 PSYCHOTEST+ - BUILD RAPIDE${NC}"
echo -e "${BLUE}===========================================${NC}"

# Variables
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
APK_NAME="psychotest_test_$TIMESTAMP.apk"
APK_PATH="build/app/outputs/flutter-apk/$APK_NAME"

echo "📅 Build: $TIMESTAMP"

# Fonction de transfert vers téléphone
transfer_to_phone() {
    echo -e "${YELLOW}📱 Recherche d'appareils connectés...${NC}"

    # Vérifier si ADB est disponible
    if command -v adb &> /dev/null; then
        ADB_CMD="adb"
    else
        # Rechercher ADB dans les emplacements courants
        POSSIBLE_PATHS=(
            "$HOME/Android/Sdk/platform-tools/adb"
            "$HOME/android-sdk/platform-tools/adb"
            "/opt/android-sdk/platform-tools/adb"
            "/usr/local/android-sdk/platform-tools/adb"
            "$ANDROID_HOME/platform-tools/adb"
            "$ANDROID_SDK_ROOT/platform-tools/adb"
        )

        for path in "${POSSIBLE_PATHS[@]}"; do
            if [ -f "$path" ] && [ -x "$path" ]; then
                ADB_CMD="$path"
                break
            fi
        done
    fi

    if [ -n "$ADB_CMD" ]; then
        # Vérifier si un appareil est connecté
        DEVICES=$($ADB_CMD devices | grep -v "List" | grep "device" | wc -l)

        if [ "$DEVICES" -gt 0 ]; then
            echo -e "${GREEN}📲 Appareil Android détecté !${NC}"

            # Créer le dossier PsychoTest sur le téléphone
            echo "📁 Création du dossier PsychoTest..."
            $ADB_CMD shell mkdir -p /sdcard/PsychoTest 2>/dev/null

            # Transférer l'APK
            echo "📤 Transfert de l'APK vers le téléphone..."
            if $ADB_CMD push "$APK_PATH" /sdcard/PsychoTest/ 2>/dev/null; then
                echo -e "${GREEN}✅ APK transféré avec succès !${NC}"
                echo -e "${GREEN}📍 Localisation: /sdcard/PsychoTest/$APK_NAME${NC}"
                echo ""
                echo -e "${YELLOW}📋 Instructions d'installation :${NC}"
                echo "   1. Sur votre téléphone, ouvrez l'explorateur de fichiers"
                echo "   2. Allez dans 'Téléchargements' ou 'Download'"
                echo "   3. Cherchez le dossier 'PsychoTest'"
                echo "   4. Appuyez sur $APK_NAME pour installer"
                echo ""
                echo -e "${GREEN}🎉 Prêt à installer sur votre téléphone !${NC}"
                return 0
            else
                echo -e "${RED}❌ Erreur lors du transfert ADB${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️ Téléphone détecté mais pas en mode débogage USB${NC}"
            echo -e "${YELLOW}💡 Activez le débogage USB :${NC}"
            echo "   Paramètres → À propos → Appuyer 7x sur Build → Options développeur → USB Debug"
        fi
    else
        echo -e "${YELLOW}⚠️ ADB n'est pas installé${NC}"
        echo -e "${YELLOW}💡 Installation : sudo apt install android-tools-adb${NC}"
    fi

    # Instructions alternatives
    echo ""
    echo -e "${YELLOW}📱 Transfert alternatif :${NC}"
    echo "   • Connectez votre téléphone en USB"
    echo "   • Copiez $APK_PATH vers votre téléphone"
    echo "   • Ou utilisez Google Drive, email, etc."
    echo ""
    echo -e "${GREEN}📂 APK local: $APK_PATH${NC}"
}

# Build rapide
echo "🔨 Build en cours..."
flutter clean && flutter pub get
flutter build apk --debug

# Vérifier et renommer l'APK
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    cp build/app/outputs/flutter-apk/app-debug.apk "$APK_PATH"
    echo -e "${GREEN}✅ APK de test généré: $APK_NAME${NC}"
    echo "📏 Taille: $(du -h "$APK_PATH" | cut -f1)"

    # Demander si on veut transférer vers le téléphone
    echo ""
    echo -e "${YELLOW}🔄 Voulez-vous transférer l'APK vers votre téléphone ? (y/n)${NC}"
    read -r response

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        transfer_to_phone
    else
        echo ""
        echo -e "${GREEN}📂 APK disponible: $APK_PATH${NC}"
        echo -e "${YELLOW}💡 Transférez-le manuellement vers votre téléphone${NC}"
    fi

    echo ""
    echo -e "${GREEN}🎯 Build terminé avec succès !${NC}"
else
    echo -e "${RED}❌ Erreur: APK non trouvé${NC}"
    exit 1
fi
