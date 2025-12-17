#!/bin/bash

# Build APK using Docker (no Flutter installation needed)
# Usage: ./build-apk-docker.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🚀 Building APK using Docker...${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed.${NC}"
    echo ""
    echo "Please install Docker Desktop first:"
    echo "  macOS: https://www.docker.com/products/docker-desktop"
    echo "  Windows: https://www.docker.com/products/docker-desktop"
    echo "  Linux: https://docs.docker.com/engine/install/"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running.${NC}"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

# Navigate to mobile directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MOBILE_DIR="$SCRIPT_DIR/mobile"

if [ ! -d "$MOBILE_DIR" ]; then
    echo -e "${RED}❌ Mobile directory not found at: $MOBILE_DIR${NC}"
    exit 1
fi

cd "$MOBILE_DIR"

echo -e "${YELLOW}📦 Pulling Flutter Docker image (first time only)...${NC}"
docker pull cirrusci/flutter:latest

echo ""
echo -e "${YELLOW}📱 Building release APK...${NC}"
echo "This may take a few minutes..."

# Build APK
docker run --rm \
  -v "$(pwd)":/app \
  -w /app \
  cirrusci/flutter:latest \
  flutter build apk --release

if [ $? -eq 0 ]; then
    APK_PATH="$MOBILE_DIR/build/app/outputs/flutter-apk/app-release.apk"
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    
    echo ""
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    echo "📦 APK Details:"
    echo "   Location: $APK_PATH"
    echo "   Size: $APK_SIZE"
    echo ""
    echo "📲 To install on your device:"
    echo "   1. Copy the APK to your Android device"
    echo "   2. Enable 'Install from Unknown Sources' in device settings"
    echo "   3. Open the APK file and install"
    echo ""
    echo "Or use ADB:"
    echo "   adb install $APK_PATH"
else
    echo ""
    echo -e "${RED}❌ Build failed. Check the error messages above.${NC}"
    exit 1
fi

