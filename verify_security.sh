#!/bin/bash

echo "🔒 Security Verification Script"
echo "================================"
echo ""

# Check if .env exists
if [ -f ".env" ]; then
    echo "✅ .env file exists"
else
    echo "❌ .env file NOT found - create it from .env.example"
    exit 1
fi

# Check if .env is in gitignore
if git check-ignore .env > /dev/null 2>&1; then
    echo "✅ .env is properly ignored by git"
else
    echo "❌ WARNING: .env is NOT ignored by git!"
    exit 1
fi

# Check if env.g.dart exists
if [ -f "lib/env/env.g.dart" ]; then
    echo "✅ env.g.dart generated successfully"
else
    echo "❌ env.g.dart NOT found - run: flutter pub run build_runner build"
    exit 1
fi

# Check if env.g.dart is in gitignore
if git check-ignore lib/env/env.g.dart > /dev/null 2>&1; then
    echo "✅ env.g.dart is properly ignored by git"
else
    echo "❌ WARNING: env.g.dart is NOT ignored by git!"
    exit 1
fi

# Check for hardcoded API keys in tracked files
echo ""
echo "🔍 Checking for hardcoded API keys..."

if git ls-files | xargs grep -l "AIzaSy" 2>/dev/null | grep -v ".env"; then
    echo "❌ WARNING: Found potential Google API keys in tracked files!"
    exit 1
else
    echo "✅ No hardcoded Google API keys found in tracked files"
fi

if git ls-files | xargs grep -l "5b3ce3597851110001cf6248" 2>/dev/null | grep -v ".env"; then
    echo "❌ WARNING: Found OpenRouteService API key in tracked files!"
    exit 1
else
    echo "✅ No hardcoded OpenRouteService API keys found in tracked files"
fi

echo ""
echo "✅ All security checks passed!"
echo ""
echo "You can safely push to GitHub now."
echo "Run: git add . && git commit -m 'Initial commit' && git push"
