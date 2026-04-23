#!/bin/bash
# HILWAY Web Deployment Script
# This script builds the Flutter Web app and deploys it to Vercel.

# Ensure we are in the project root
cd "$(dirname "$0")/.."

echo "🚀 Building Flutter Web (Release)..."

# Check if BACKEND_URL is set
if [ -z "$BACKEND_URL" ]; then
    echo "⚠️  BACKEND_URL not found in shell environment."
    echo "   Using default from .env if available."
else
    echo "✅ Using BACKEND_URL: $BACKEND_URL"
fi

echo "🔄 Syncing version.json with pubspec.yaml..."
VERSION=$(grep '^version: ' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)
cat <<EOF > web/version.json
{
  "version": "$VERSION",
  "build_number": $(date +%s),
  "force_update": false
}
EOF
echo "✅ Set version.json to v$VERSION"

# Build with dart-define to inject the backend URL
flutter build web --release --dart-define=BACKEND_URL="$BACKEND_URL"

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo "📦 Injecting Vercel configuration for SPA routing..."
    if [ -f "vercel.json" ]; then
        cp vercel.json build/web/
        echo "✅ vercel.json copied to build/web/"
    else
        echo "⚠️ Warning: vercel.json not found in root."
    fi

    # Deploy
    if command -v vercel &> /dev/null
    then
        echo "☁️ Deploying to Vercel..."
        vercel deploy build/web --prod
    else
        echo "💡 Vercel CLI not found. Run: npm install -g vercel"
    fi
else
    echo "❌ Build failed. Deployment aborted."
    exit 1
fi

echo "✨ Done!"
