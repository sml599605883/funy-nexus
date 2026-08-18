import 'package:permission_handler/permission_handler.dart';

typedef PermissionRequest = Future<PermissionStatus> Function();
typedef LocationServiceStatusProvider = Future<ServiceStatus> Function();
typedef LocationPermissionStatusProvider = Future<PermissionStatus> Function();

enum LocationAccessDecision {
  granted,
  denied,
  settingsRequired,
  serviceDisabled,
}

class PermissionCoordinator {
  PermissionCoordinator({
    PermissionRequest? requestLocation,
    PermissionRequest? requestCamera,
    LocationServiceStatusProvider? locationServiceStatusProvider,
    LocationPermissionStatusProvider? locationPermissionStatusProvider,
  }) : _requestLocation =
           requestLocation ?? Permission.locationWhenInUse.request,
       _locationServiceStatusProvider =
           locationServiceStatusProvider ??
           (() => Permission.locationWhenInUse.serviceStatus),
       _locationPermissionStatusProvider =
           locationPermissionStatusProvider ??
           (() => Permission.locationWhenInUse.status),
       _usesDirectLocationRequest =
           requestLocation != null &&
           locationServiceStatusProvider == null &&
           locationPermissionStatusProvider == null,
       _requestCamera = requestCamera ?? Permission.camera.request;

  static final PermissionCoordinator instance = PermissionCoordinator();

  final PermissionRequest _requestLocation;
  final LocationServiceStatusProvider _locationServiceStatusProvider;
  final LocationPermissionStatusProvider _locationPermissionStatusProvider;
  final bool _usesDirectLocationRequest;
  final PermissionRequest _requestCamera;

  Future<PermissionStatus> requestLocation() => _requestLocation();

  Future<LocationAccessDecision> requestLocationAccess() async {
    if (_usesDirectLocationRequest) {
      return _decisionFor(await _requestLocation(), afterRequest: true);
    }
    try {
      final serviceStatus = await _locationServiceStatusProvider();
      if (serviceStatus != ServiceStatus.enabled) {
        return LocationAccessDecision.serviceDisabled;
      }

      final currentStatus = await _locationPermissionStatusProvider();
      if (_isGranted(currentStatus)) return LocationAccessDecision.granted;
      if (_requiresSettings(currentStatus)) {
        return LocationAccessDecision.settingsRequired;
      }

      return _decisionFor(await _requestLocation(), afterRequest: true);
    } catch (_) {
      return LocationAccessDecision.denied;
    }
  }

  Future<PermissionStatus> requestCamera() => _requestCamera();

  LocationAccessDecision _decisionFor(
    PermissionStatus status, {
    bool afterRequest = false,
  }) {
    if (_isGranted(status)) return LocationAccessDecision.granted;
    if (_requiresSettings(status)) {
      return LocationAccessDecision.settingsRequired;
    }
    if (afterRequest) return LocationAccessDecision.settingsRequired;
    return LocationAccessDecision.denied;
  }

  bool _isGranted(PermissionStatus status) =>
      status == PermissionStatus.granted || status == PermissionStatus.limited;

  bool _requiresSettings(PermissionStatus status) =>
      status == PermissionStatus.permanentlyDenied ||
      status == PermissionStatus.restricted;
}
