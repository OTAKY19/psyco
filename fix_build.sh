#!/bin/bash

echo "🔧 Réparation des problèmes de build Flutter..."

# Arrêter tous les processus Java/Gradle en cours
echo "🛑 Arrêt des processus en cours..."
pkill -f "java" || true
pkill -f "gradle" || true

# Nettoyer complètement le cache Gradle
echo "🧹 Nettoyage complet du cache Gradle..."
rm -rf ~/.gradle/caches/*
rm -rf ~/.gradle/daemon/*
rm -rf ~/.gradle/wrapper/dists/*

# Nettoyer le projet Flutter
echo "🧽 Nettoyage du projet Flutter..."
flutter clean

# Restaurer les dépendances
echo "📦 Restauration des dépendances..."
flutter pub get

# Nettoyer et régénérer les fichiers Android
echo "🤖 Nettoyage des fichiers Android..."
cd android
./gradlew clean || true
./gradlew cleanBuildCache || true
cd ..

# Restaurer les dépendances Android
echo "🔄 Restauration des dépendances Android..."
cd android
./gradlew build --refresh-dependencies || true
cd ..

# Nettoyer à nouveau
echo "🔄 Nettoyage final..."
flutter clean

echo "✅ Réparation terminée!"
echo "🚀 Vous pouvez maintenant essayer de build le projet."
echo ""
echo "Commandes suggérées:"
echo "  flutter build apk --debug"
echo "  flutter build apk --release"
