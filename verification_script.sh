#!/bin/bash

# Script de vérification pour PsychoTest+
# Ce script vérifie les corrections apportées et teste l'application

echo "🔍 Vérification de l'application PsychoTest+"
echo "=============================================="

# Vérifier si Flutter est installé
echo "📱 Vérification de Flutter..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter est installé"
    flutter --version
else
    echo "❌ Flutter n'est pas installé"
    echo "   Veuillez installer Flutter depuis https://flutter.dev"
    exit 1
fi

# Vérifier la structure du projet
echo ""
echo "📁 Vérification de la structure du projet..."
if [ -f "pubspec.yaml" ]; then
    echo "✅ pubspec.yaml trouvé"
else
    echo "❌ pubspec.yaml non trouvé"
    exit 1
fi

if [ -d "lib" ]; then
    echo "✅ Dossier lib trouvé"
else
    echo "❌ Dossier lib non trouvé"
    exit 1
fi

# Nettoyer et récupérer les dépendances
echo ""
echo "🧹 Nettoyage et récupération des dépendances..."
flutter clean
flutter pub get

# Analyser le code
echo ""
echo "🔍 Analyse du code..."
flutter analyze > analysis_report.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Analyse du code réussie - aucune erreur critique"
else
    echo "⚠️  Analyse du code terminée avec des avertissements"
    echo "   Consultez analysis_report.txt pour les détails"
fi

# Vérifier les corrections primaryColor
echo ""
echo "🎨 Vérification des corrections primaryColor..."
primary_color_count=$(grep -r "\.primaryColor" lib/ --include="*.dart" | wc -l)
if [ $primary_color_count -eq 0 ]; then
    echo "✅ Toutes les références primaryColor ont été corrigées"
else
    echo "⚠️  $primary_color_count références primaryColor restantes"
    echo "   Fichiers concernés :"
    grep -r "\.primaryColor" lib/ --include="*.dart" | cut -d: -f1 | sort | uniq
fi

# Vérifier les APIs withValues
echo ""
echo "🔧 Vérification des APIs withValues..."
with_values_count=$(grep -r "withValues(" lib/ --include="*.dart" | wc -l)
echo "ℹ️  $with_values_count utilisations de withValues() trouvées"

# Vérifier les APIs withOpacity
with_opacity_count=$(grep -r "withOpacity(" lib/ --include="*.dart" | wc -l)
if [ $with_opacity_count -gt 0 ]; then
    echo "⚠️  $with_opacity_count utilisations de withOpacity() trouvées"
    echo "   Considérez les remplacer par withValues(alpha:) pour la cohérence"
else
    echo "✅ Aucune utilisation de withOpacity() trouvée"
fi

# Tenter de compiler l'application
echo ""
echo "🔨 Test de compilation..."
flutter build apk --debug > build_report.txt 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Compilation réussie !"
    echo "   L'application peut être testée avec 'flutter run'"
else
    echo "❌ Erreurs de compilation détectées"
    echo "   Consultez build_report.txt pour les détails"
    
    # Afficher les erreurs les plus importantes
    echo ""
    echo "🚨 Erreurs principales :"
    grep -i "error:" build_report.txt | head -5
fi

# Résumé
echo ""
echo "📊 Résumé de la vérification"
echo "============================"
echo "- Références primaryColor restantes : $primary_color_count"
echo "- Utilisations withValues() : $with_values_count"
echo "- Utilisations withOpacity() : $with_opacity_count"

if [ $primary_color_count -eq 0 ] && [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Félicitations ! L'application semble prête pour les tests"
    echo "   Lancez 'flutter run' pour tester l'application"
else
    echo ""
    echo "⚠️  Des corrections supplémentaires peuvent être nécessaires"
    echo "   Consultez CORRECTIONS_APPORTEES.md pour plus de détails"
fi

echo ""
echo "📝 Rapports générés :"
echo "   - analysis_report.txt : Rapport d'analyse du code"
echo "   - build_report.txt : Rapport de compilation"
echo "   - CORRECTIONS_APPORTEES.md : Documentation des corrections"