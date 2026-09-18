#!/bin/bash
# simple-build.sh - Build APK simple avec Flutter

echo "🔧 Construction APK simple..."

# Nettoyer les anciens builds
flutter clean

# Récupérer les dépendances
flutter pub get

# Construire l'APK
echo "🏗️  Construction APK..."
flutter build apk --debug --no-tree-shake-icons

# Vérifier le résultat
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "✅ APK créé avec succès !"
    echo "📱 APK disponible dans: build/app/outputs/flutter-apk/app-debug.apk"
    echo "📏 Taille de l'APK:"
    ls -lh build/app/outputs/flutter-apk/app-debug.apk
else
    echo "❌ Échec de création APK"
    exit 1
fi
