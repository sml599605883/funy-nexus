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
}
