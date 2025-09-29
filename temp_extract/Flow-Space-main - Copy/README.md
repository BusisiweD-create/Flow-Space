# Flow-Space - Project Management Platform

A comprehensive project management platform built with Flutter, designed to track deliverables, manage sprints, and handle client approvals.

## 🚀 Features

### Core Features
- **Deliverable Management**: Create, track, and manage project deliverables with Definition of Done
- **Sprint Performance**: Monitor sprint metrics, velocity, and completion rates
- **Client Approval System**: Streamlined sign-off process with digital approvals
- **File Repository**: Centralized file storage and management system
- **Notification System**: Real-time notifications for project updates
- **User Authentication**: Secure login and registration system

### New Features Added
- **Approvals Page**: Manage approval requests with approve/deny functionality
- **Repository Page**: File management with search and upload capabilities
- **Notifications Page**: Centralized notification management with read/unread status

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.0+ with Dart
- **State Management**: Riverpod + Provider
- **Navigation**: Go Router
- **Backend**: Node.js/Express with PostgreSQL
- **UI**: Material Design 3 with custom theming
- **Charts**: FL Chart for data visualization

## 📋 Prerequisites

- **Flutter SDK** (3.0.0 or higher)
- **Node.js** (for backend)
- **PostgreSQL** (for database)
- **Git** (for version control)

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone <your-repository-url>
cd Flow-Space-main
```

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Install Backend Dependencies
```bash
cd backend
npm install
```

### 4. Setup Database
- Install PostgreSQL
- Create database named `flow_space`
- Run the SQL scripts in the root directory

### 5. Run the Application

**Frontend (Flutter):**
```bash
flutter run -d chrome
```

**Backend (Node.js):**
```bash
cd backend
npm start
```

## 📱 Available Screens

- **Welcome Screen**: Landing page with app introduction
- **Authentication**: Login and registration screens
- **Dashboard**: Main overview with metrics and quick access
- **Deliverables**: Create and manage project deliverables
- **Sprints**: Sprint planning and performance tracking
- **Approvals**: Manage approval requests (NEW)
- **Repository**: File management system (NEW)
- **Notifications**: Notification center (NEW)

## 🏗️ Project Structure

```
lib/
├── config/                 # Configuration files
├── models/                 # Data models
│   ├── deliverable.dart
│   ├── sprint.dart
│   ├── approval_request.dart    # NEW
│   ├── repository_file.dart     # NEW
│   └── notification_item.dart   # NEW
├── providers/              # State management
├── screens/                # UI screens
│   ├── approvals_screen.dart    # NEW
│   ├── repository_screen.dart   # NEW
│   ├── notifications_screen.dart # NEW
│   └── ...
├── services/               # Business logic
├── widgets/                # Reusable components
└── main.dart              # App entry point

backend/
├── server.js              # Express server
├── package.json           # Backend dependencies
└── ...
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
