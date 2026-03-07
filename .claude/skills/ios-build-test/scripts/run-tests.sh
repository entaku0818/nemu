#!/bin/bash

# iOS Build & Test Script
# Usage: ./run-tests.sh [project_path] [scheme] [test_name]

set -e

PROJECT_PATH="${1:-.}"
SCHEME="${2}"
TEST_NAME="${3}"
SIMULATOR="${SIMULATOR:-iPhone 16}"

# Find .xcodeproj
if [ -z "$PROJECT_PATH" ] || [ "$PROJECT_PATH" = "." ]; then
    PROJECT=$(find . -name "*.xcodeproj" -maxdepth 3 | head -n 1)
    if [ -z "$PROJECT" ]; then
        echo "Error: No .xcodeproj found"
        exit 1
    fi
else
    PROJECT="$PROJECT_PATH"
fi

echo "📦 Project: $PROJECT"

# Get scheme if not provided
if [ -z "$SCHEME" ]; then
    echo "Available schemes:"
    xcodebuild -list -project "$PROJECT" | grep -A 100 "Schemes:" | tail -n +2
    exit 0
fi

echo "🎯 Scheme: $SCHEME"
echo "📱 Simulator: $SIMULATOR"

# Build
echo ""
echo "🔨 Building..."
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    build

# Test
echo ""
if [ -n "$TEST_NAME" ]; then
    echo "🧪 Running specific test: $TEST_NAME"
    xcodebuild -project "$PROJECT" \
        -scheme "$SCHEME" \
        test \
        -destination "platform=iOS Simulator,name=$SIMULATOR" \
        -only-testing:"$TEST_NAME"
else
    echo "🧪 Running all tests..."
    xcodebuild -project "$PROJECT" \
        -scheme "$SCHEME" \
        test \
        -destination "platform=iOS Simulator,name=$SIMULATOR"
fi

echo ""
echo "✅ Done!"
