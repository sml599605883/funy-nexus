# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Fund Nexus is a Flutter financial application with iOS native integrations. The app uses flutter_bloc for state management, implements a secure API layer with HMAC-SHA256 signing and AES-CBC encryption, and includes native iOS bridges for device reporting, face liveness verification, and push notification routing.

## Build & Development Commands

### Running the App
The app requires runtime configuration via `dart-define` flags. Environment-specific values must be provided:

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.example.com/api \
  --dart-define=WEB_BASE_URL=https://staging.example.com \
  --dart-define=API_SIGNING_SECRET=server-provided-secret \
  --dart-define=API_AES_KEY=server-provided-aes-key \
  --dart-define=API_AES_IV=server-provided-aes-iv
```

For debug capture with a proxy:
```bash
flutter run \
  --dart-define=CAPTURE_PROXY_HOST=192.168.1.10 \
  --dart-define=CAPTURE_PROXY_PORT=8888 \
  --dart-define=CAPTURE_ALLOW_BAD_CERTIFICATES=true
```

Note: Production builds must use HTTPS for all URLs and `CAPTURE_ALLOW_BAD_CERTIFICATES` must be false.

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/core/push/push_deep_link_test.dart

# Run tests in a directory
flutter test test/core/push/

# Run with coverage
flutter test --coverage
```

### Static Analysis
```bash
# Analyze entire project
flutter analyze

# Analyze specific directory
flutter analyze lib/core/push/
```

## Architecture

### Layer Structure

**Core Layer** (`lib/core/`):
- `config/` - App configuration from dart-define environment variables
- `network/` - API client with HMAC-SHA256 signing, AES encryption, and session management
- `session/` - Session storage and expiry coordination
- `report/` - Device reporting and native bridge integration
- `push/` - iOS push notification routing with deep link parsing
- `permissions/` - Permission coordination
- `json/` - Type-safe JSON wrapper utilities

**App Layer** (`lib/app/`):
- `startup/` - App initialization and network gate
- `theme/` - Material theme configuration
- `navigation/` - Route observer

**Features Layer** (`lib/features/`):
- Each feature is self-contained with `data/`, `state/` (Cubits), and `widgets/`
- `main_shell/` - Tab navigation shell with MainTabCubit
- `home/` - Home screen with product listings
- `login/` - Authentication flow
- `product/` - Product application flow including certification, credit review, and WebView
- `mine/` - Profile/settings

### State Management

Uses **flutter_bloc** with Cubit pattern:
- `HomeCubit` - Home screen data loading
- `LoginCubit` - Login flow state
- `MainTabCubit` - Tab navigation state (simple int cubit)
- State classes extend `Cubit<T>` where T is the state type

### Network Architecture

**API Client** (`lib/core/network/api_client.dart`):
- All requests go through centralized `ApiClient`
- Automatic HMAC-SHA256 signing via `ApiSignature`
- Public params include device info, version, IDFV (persisted in Keychain)
- Response envelope uses `fasciatis`, `bravo`, and `foresight` fields
- Code `0` = success, `-2` = session expired
- Encrypted payloads use AES-CBC with PKCS7 padding and Base64 encoding

**Session Management**:
- Session IDs stored in platform secure storage via `SessionStore`
- `SessionExpiryCoordinator` handles automatic session expiry
- Phone numbers can be retained separately when signing out

**Proxy Support**:
- iOS respects system HTTP proxy when no explicit proxy is configured
- Explicit `CAPTURE_PROXY_HOST`/`CAPTURE_PROXY_PORT` takes priority
- Only for debug builds - never accept invalid certificates in production

### iOS Native Bridges

**FundReportBridge** (`ios/Runner/FundReportBridge.swift`):
- EventChannel for push notifications and tracking status changes
- MethodChannel for device snapshots, location, push tokens
- Handles notification payload extraction with queue for pre-Flutter events
- TrustDecision SDK integration for face liveness

**AppDelegate** (`ios/Runner/AppDelegate.swift`):
- UserNotifications delegate implementation
- Forwards notification payloads to FundReportBridge
- Handles app launch from notification

### Push Notification Routing

**Deep Link Format**: `ph://fund-nexus/ios/PageName?param=value`

**Components**:
1. `IosNotificationRouteCoordinator` - Listens to native bridge events, queues routes until navigation ready
2. `PushDeepLinkParser` - Parses URLs and extracts parameters (productId, orderNo, status)
3. `PushNavigationHelper` - Executes navigation based on parsed links

**Initialization** (in `main.dart`):
```dart
IosNotificationRouteCoordinator.configure(
  openRoute: PushNavigationHelper.navigateToTarget,
);
IosNotificationRouteCoordinator.instance.start();
```

**Obfuscated Page Names**:
Push notification URLs use obfuscated names for security. The mapping between obfuscated names and actual pages should be obtained from the project's API documentation or MyTools. Current mappings in `lib/core/push/push_deep_link.dart` may need to be updated based on the actual backend configuration.

To add new page mappings, update `_kindForAlias()` in `push_deep_link.dart`.

### WebView Integration

**ProductWebPage** (`lib/features/product/web/product_web_page.dart`):
- Uses flutter_inappwebview for H5 integration
- Bidirectional bridge via `ProductWebBridgeDispatcher`
- Supports commands: upload risk, open URL, close, home navigation, public params, retry order, change account
- WebView can trigger native actions through bridge methods

## Important Conventions

### Security
- Never log or expose crypto configuration (API_AES_KEY, API_AES_IV, API_SIGNING_SECRET)
- Production builds require HTTPS for all URLs
- Session IDs are in secure storage, not shared preferences
- IDFV is persisted in Keychain for stable device identification

### Error Handling
- API errors are handled via `ApiException` with structured error messages
- Response envelope parsing extracts code and message from standard fields
- Session expiry (code -2) triggers automatic logout flow via `SessionExpiryCoordinator`

### Testing
- Push notification routing has comprehensive test coverage (19 tests)
- Tests use dependency injection for mockability
- Native bridge functionality is testable via test constructors with mock channels

### File Naming
- Cubits: `*_cubit.dart` with `*State` class
- Data classes: `*_data.dart` or `*_models.dart`
- Widgets: `*_page.dart` for full screens, `*_widget.dart` for components
- Native bridges: `*Bridge.swift`

## iOS-Specific Notes

### Push Notification Payload Format
Supports three formats:
1. `{"url": "ph://fund-nexus/ios/Page"}`
2. `{"params": {"url": "ph://fund-nexus/ios/Page"}}`
3. `{"params": "{\"url\":\"ph://fund-nexus/ios/Page\"}"}`

### Face Liveness
- TrustDecision SDK integrated via `FaceLivenessBridge`
- Initialized on app launch with partner credentials
- Returns success/failure with liveness_id and captured image

### System Integration
- Device name resolution via `/viler/resite` endpoint on startup
- Location services with permission coordination
- App Tracking Transparency (ATT) integration for iOS 14+
- Adjust SDK for attribution tracking

## Common Patterns

### Making API Requests
```dart
final client = context.read<ApiClient>();
final response = await client.post<DataType>(
  '/endpoint',
  data: {'key': 'value'},
  decoder: (data) => DataType.fromJson(data),
);
```

### Navigation
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => NextPage()),
);
```

### State Management
```dart
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit() : super(FeatureState.initial());
  
  Future<void> loadData() async {
    emit(state.copyWith(loading: true));
    // fetch data
    emit(state.copyWith(loading: false, data: result));
  }
}
```

### Accessing Native Bridge
```dart
final bridge = ReportNativeBridge();
final snapshot = await bridge.getDeviceSnapshot();
final location = await bridge.getLocation();
```

[mcp.api-doc.env]
API_PREFIX = "ph_fund_nexus_ios"