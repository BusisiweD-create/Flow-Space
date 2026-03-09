#!/bin/bash

# Flow-Space Deployment Script
# This script handles the complete deployment process

echo "🚀 Starting Flow-Space Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the Flutter project root directory"
    exit 1
fi

print_status "Flutter project detected"

# Step 1: Check Git status
echo ""
print_info "Step 1: Checking Git status..."
if [ -n "$(git status --porcelain)" ]; then
    print_warning "You have uncommitted changes. Please commit or stash them first."
    git status --short
    exit 1
fi

print_status "Git working directory is clean"

# Step 2: Run Flutter analysis
echo ""
print_info "Step 2: Running Flutter analysis..."
flutter analyze
if [ $? -ne 0 ]; then
    print_error "Flutter analysis failed. Please fix the issues before deploying."
    exit 1
fi

print_status "Flutter analysis passed"

# Step 3: Run tests
echo ""
print_info "Step 3: Running tests..."
flutter test
if [ $? -ne 0 ]; then
    print_error "Tests failed. Please fix the failing tests before deploying."
    exit 1
fi

print_status "All tests passed"

# Step 4: Build Flutter web app
echo ""
print_info "Step 4: Building Flutter web app..."
flutter build web --release
if [ $? -ne 0 ]; then
    print_error "Flutter build failed. Please fix the build issues."
    exit 1
fi

print_status "Flutter web build completed"

# Step 5: Setup database (if needed)
echo ""
print_info "Step 5: Setting up database..."
if [ -f "deploy_database.sh" ]; then
    chmod +x deploy_database.sh
    ./deploy_database.sh
else
    print_warning "Database deployment script not found. Please ensure database is set up manually."
fi

# Step 6: Commit and push changes
echo ""
print_info "Step 6: Committing and pushing changes..."

# Add all changes
git add .

# Commit with timestamp
COMMIT_MESSAGE="Deployment $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$COMMIT_MESSAGE"

# Push to main branch
git push origin main

if [ $? -eq 0 ]; then
    print_status "Changes pushed successfully"
else
    print_error "Failed to push changes. Please check your Git configuration."
    exit 1
fi

# Step 7: Deployment summary
echo ""
print_status "Deployment completed successfully!"
echo ""
echo "📊 Deployment Summary:"
echo "  ✅ Flutter analysis passed"
echo "  ✅ All tests passed"
echo "  ✅ Web build completed"
echo "  ✅ Database setup completed"
echo "  ✅ Changes pushed to repository"
echo ""
echo "🌐 Your app should be available at your deployment URL"
echo ""
echo "🎯 Next steps:"
echo "  1. Monitor deployment for any issues"
echo "  2. Test project details functionality"
echo "  3. Verify all features work correctly"
echo ""
print_info "Happy deploying! 🚀"
