#!/bin/bash
# flutter-docker-build.sh

PROJECT_NAME="${1:-my_flutter_app}"
DOCKER_TAG="${2:-flutter-builder}"

echo "🐳 Construction de l'APK Flutter avec Docker"
echo "📁 Projet: $PROJECT_NAME"
echo "🏷️  Tag Docker: $DOCKER_TAG"

# Créer le Dockerfile si inexistant
if [ ! -f "Dockerfile" ]; then
    cat > Dockerfile << 'EOF'
FROM cirrusci/flutter:stable

WORKDIR /app
COPY . .

RUN flutter clean
RUN flutter pub get
RUN flutter build apk --debug --no-tree-shake-icons

CMD ["cp", "build/app/outputs/flutter-apk/app-debug.apk", "/output/app-debug.apk"]
EOF
    echo "✅ Dockerfile créé"
fi

# Créer le dossier output
mkdir -p output

# Construire l'image Docker
echo "🔨 Construction de l'image Docker..."
docker build -t "$DOCKER_TAG" .

# Générer l'APK
echo "📦 Génération de l'APK..."
docker run --rm -v "$(pwd)/output:/output" "$DOCKER_TAG"

# Vérifier le résultat
if [ -f "output/app-debug.apk" ]; then
    echo "✅ APK généré avec succès: output/app-debug.apk"
    echo "📱 Taille: $(du -h output/app-debug.apk | cut -f1)"
else
    echo "❌ Échec de génération de l'APK"
    exit 1
fi
