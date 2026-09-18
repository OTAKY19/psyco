#!/bin/bash

echo "🧹 Nettoyage du projet PsychoTest+..."

# Supprimer les fichiers temporaires et caches
echo "📁 Suppression des fichiers temporaires..."
rm -rf ~/.gradle/caches
rm -rf ~/.gradle/wrapper
rm -rf build/
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
rm -rf .packages
rm -f pubspec.lock

# Supprimer les fichiers de sauvegarde
echo "💾 Suppression des fichiers de sauvegarde..."
find lib/ -name "*.backup" -type f -delete
find . -name "*.backup" -type f -delete

# Supprimer les fichiers de test temporaires
echo "🧪 Suppression des fichiers de test temporaires..."
find . -name "test_*.dart" -type f -delete
find . -name "test_demo_system.dart" -type f -delete
find . -name "test_routes_navigation.dart" -type f -delete
find . -name "test_progressive_results.dart" -type f -delete

# Supprimer les fichiers APK obsolètes
echo "📱 Suppression des anciens APKs..."
find . -name "*.apk" -path "*/build/app/outputs/*" -delete

# Supprimer les fichiers de documentation temporaires
echo "📄 Suppression des fichiers de documentation temporaires..."
find . -maxdepth 1 -name "*.md" -type f -delete

# Nettoyer le cache Flutter
echo "🔄 Nettoyage du cache Flutter..."
flutter clean

# Restaurer pubspec.lock
echo "📦 Restauration des dépendances..."
flutter pub get

echo "✅ Nettoyage terminé!"
echo "🚀 Le projet est maintenant propre et prêt pour le build."
