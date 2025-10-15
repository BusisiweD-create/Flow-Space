# Khono - Social Learning Platform

A modern social learning platform built with Flutter, designed to connect learners and educators in an interactive, engaging environment.

## 🚀 Features

- **Social Learning**: Connect with peers and educators
- **Interactive Content**: Rich media support for videos, audios, and documents
- **Real-time Communication**: Backend-powered real-time features
- **Cross-platform**: Runs on iOS, Android, and Web
- **Modern UI**: Beautiful, responsive design with smooth animations

## 🛠️ Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod
- **Backend**: Custom backend API with role-based authentication
- **Routing**: Go Router
- **UI Components**: Custom components with animations
- **Image Handling**: Cached Network Images
- **File Management**: File Picker, Path Provider

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0.0 or higher)
- **Dart SDK** (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Git** (for version control)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd Flow-Space
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Backend Setup

1. **Configure Backend Connection**:
   - Update API endpoints in `config/environment.dart`
   - Configure authentication settings

2. **Environment Configuration**:
   - Edit `config/environment.dart` with your actual configuration values
   - Update API URLs, authentication keys, and other settings

### 4. Asset Directories

The project includes organized asset directories:
- `assets/fonts/` - Custom fonts
- `assets/images/` - Images and icons
- `assets/videos/` - Video content
- `assets/audios/` - Audio files
- `assets/rive_animations/` - Rive animations
- `assets/pdfs/` - PDF documents
- `assets/jsons/` - JSON configuration files

### 5. Run the Application

```bash
# Debug mode
flutter run

# Release mode
flutter run --release

# Web version
flutter run -d web-server --web-port 3000
```

## 🏗️ Project Structure

```
lib/
├── config/                 # Configuration files
│   └── environment.dart    # Environment settings
├── models/                 # Data models
├── providers/              # Riverpod providers
├── screens/                # UI screens
├── widgets/                # Reusable widgets
├── services/               # Business logic services
├── utils/                  # Utility functions
└── main.dart              # App entry point

assets/
├── fonts/                  # Custom fonts
├── images/                 # Images and icons
├── videos/                 # Video content
├── audios/                 # Audio files
├── rive_animations/        # Rive animations
├── pdfs/                   # PDF documents
└── jsons/                  # JSON files
```

## 🔧 Development

### Code Quality

The project uses strict linting rules defined in `analysis_options.yaml`:

- **Code Style**: Consistent formatting and naming conventions
- **Performance**: Optimized widget usage and state management
- **Documentation**: Clear code documentation
- **Error Prevention**: Comprehensive error handling

### VS Code Configuration

The project includes VS Code settings for optimal development:

- **Auto-formatting**: Code formatting on save
- **Linting**: Real-time error detection
- **Debugging**: Pre-configured launch configurations
- **Extensions**: Recommended Flutter/Dart extensions

### Git Workflow

1. **Feature Branches**: Create feature branches for new development
2. **Commit Messages**: Use conventional commit messages
3. **Pull Requests**: Review all changes before merging
4. **Code Review**: Ensure code quality and standards

## 🚀 Deployment

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Build iOS app
flutter build ios --release
```

### Web

```bash
# Build web app
flutter build web --release
```

## 📱 Platform Support

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 11+)
- ✅ **Web** (Modern browsers)
- ✅ **Windows** (Windows 10+)
- ✅ **macOS** (macOS 10.14+)
- ✅ **Linux** (Ubuntu 18.04+)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions:

1. Check the [Issues](https://github.com/your-repo/issues) page
2. Create a new issue with detailed information
3. Contact the development team

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- The open-source community for various packages
- Contributors and testers

---

**Happy Learning with Khono! 🎓**
