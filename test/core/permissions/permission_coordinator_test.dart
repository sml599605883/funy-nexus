import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test('requests feature permissions at their entry points', () async {
    var locationCalls = 0;
    var cameraCalls = 0;
    final coordinator = PermissionCoordinator(
      requestLocation: () async {
        locationCalls++;
        return PermissionStatus.granted;
      },
      requestCamera: () async {
        cameraCalls++;
        return PermissionStatus.granted;
      },
    );

    await coordinator.requestLocation();
    await coordinator.requestCamera();
    expect(locationCalls, 1);
    expect(cameraCalls, 1);
  });

  test('does not request location when services are disabled', () async {
    var requestCalls = 0;
    final coordinator = PermissionCoordinator(
      requestLocation: () async {
        requestCalls++;
        return PermissionStatus.granted;
      },
      locationServiceStatusProvider: () async => ServiceStatus.disabled,
      locationPermissionStatusProvider: () async => PermissionStatus.denied,
    );

    expect(
      await coordinator.requestLocationAccess(),
      LocationAccessDecision.serviceDisabled,
    );
    expect(requestCalls, 0);
  });

  test('does not request location when access is already granted', () async {
    var requestCalls = 0;
    final coordinator = PermissionCoordinator(
      requestLocation: () async {
        requestCalls++;
        return PermissionStatus.granted;
      },
      locationServiceStatusProvider: () async => ServiceStatus.enabled,
      locationPermissionStatusProvider: () async => PermissionStatus.granted,
    );

    expect(
      await coordinator.requestLocationAccess(),
      LocationAccessDecision.granted,
    );
    expect(requestCalls, 0);
  });

  test('maps a denied request to the settings path', () async {
    final coordinator = PermissionCoordinator(
      requestLocation: () async => PermissionStatus.denied,
      locationServiceStatusProvider: () async => ServiceStatus.enabled,
      locationPermissionStatusProvider: () async => PermissionStatus.denied,
    );

    expect(
      await coordinator.requestLocationAccess(),
      LocationAccessDecision.settingsRequired,
    );
  });
}
