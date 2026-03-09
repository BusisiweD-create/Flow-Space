# Version Control System for Flow-Space

## Overview
This document outlines the version control system implemented for the Flow-Space application using the format: `Environment-Year-Month-Day-ReleaseNumber`

## Version Format
- **Format**: `ENV-YYYY-MM-DD-RR`
- **Example**: `SIT-2025-12-20-01`

### Components:
- **Environment**: SIT, UAT, PROD, DEV
- **Year**: 4-digit year (e.g., 2025)
- **Month**: 2-digit month (01-12)
- **Day**: 2-digit day (01-31)
- **Release Number**: 2-digit release number for the day (01-99)

## Environment Types
- **SIT**: System Integration Testing
- **UAT**: User Acceptance Testing
- **PROD**: Production Environment
- **DEV**: Development Environment

## Implementation Files

### Core Version Control
- `lib/utils/version_control.dart` - Core version generation logic
- `lib/services/version_service.dart` - Service layer for version management

### UI Components
- `lib/widgets/version_display.dart` - Version display widgets
- `lib/main_versioned.dart` - Example app with version integration

### Build Scripts
- `scripts/generate_version.dart` - Script to generate version files

## Usage Examples

### Generate Current Version
```dart
import 'package:flow_space/utils/version_control.dart';

String version = VersionControl.generateVersionNumber();
// Returns: "SIT-2025-12-20-01"
```

### Get Version Details
```dart
Map<String, dynamic> info = VersionControl.getVersionInfo();
// Returns detailed version information including week number, day of week, etc.
```

### Display Version in UI
```dart
import 'package:flow_space/widgets/version_display.dart';

// Add version banner
VersionBanner(),

// Add version display widget
VersionDisplay(),
```

### Environment Detection
```dart
import 'package:flow_space/services/version_service.dart';

bool isProduction = VersionService.isProductionEnvironment();
bool isStaging = VersionService.isStagingEnvironment();
bool isDevelopment = VersionService.isDevelopmentEnvironment();
```

## Build Integration

### Generate Version Files
Run the version generation script:
```bash
dart scripts/generate_version.dart
```

This creates:
- `build_version.txt` - Contains the current version string
- `version_info.json` - Contains detailed version information in JSON format

### Environment Configuration
To change the environment, modify the `environment` constant in `lib/utils/version_control.dart`:

```dart
static const String environment = 'SIT'; // Change to 'UAT', 'PROD', or 'DEV'
```

## Deployment Process

### Before Deployment
1. Update environment constant if needed
2. Run version generation script
3. Commit version files to repository
4. Tag the release with the version number

### Example Deployment Commands
```bash
# Generate version
dart scripts/generate_version.dart

# Commit changes
git add .
git commit -m "Release $(cat build_version.txt)"

# Tag release
git tag -a "$(cat build_version.txt)" -m "Release $(cat build_version.txt)"

# Push to remote
git push origin main --tags
```

## Calendar Week Integration

The version system includes calendar week information for client reporting:
- Week number is calculated based on ISO week date system
- Day of week (1-7, Monday-Sunday)
- This information is available in version details for senior developer review

## Client Logic Integration

When discussing version logic with senior developers:
1. Reference the calendar week for release scheduling
2. Use the environment prefix to indicate deployment stage
3. Include release number for multiple releases per day
4. Maintain consistent format across all environments

## Version History Tracking

The system automatically tracks:
- Build timestamp
- Calendar week number
- Day of week
- Environment type
- Release sequence

This information can be used for:
- Release scheduling
- Bug tracking
- Feature deployment coordination
- Client reporting

## Examples

### Typical Development Day
- Morning: `SIT-2025-12-20-01` (First SIT deployment)
- Afternoon: `SIT-2025-12-20-02` (Second SIT deployment after fixes)
- Evening: `UAT-2025-12-20-01` (UAT deployment for client review)

### Production Release
- `PROD-2025-12-20-01` (First production release of the day)

### Multiple Environment Releases
- `DEV-2025-12-20-01` (Development testing)
- `SIT-2025-12-20-01` (System integration)
- `UAT-2025-12-20-01` (User acceptance)
- `PROD-2025-12-20-01` (Production deployment)
