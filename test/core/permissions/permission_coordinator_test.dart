import 'package:flutter_test/flutter_test.dart';
import 'package:fund_nexus/core/permissions/permission_coordinator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  test(
    'requests each sensitive permission at its feature entry point',
    () async {
      var locationCalls = 0;
      var cameraCalls = 0;
      var photosCalls = 0;
      final coordinator = PermissionCoordinator(
        requestLocation: () async {
          locationCalls++;
          return PermissionStatus.granted;
        },
        requestCamera: () async {
          cameraCalls++;
          return PermissionStatus.granted;
        },
        requestPhotos: () async {
          photosCalls++;
          return PermissionStatus.granted;
        },
      );

      await coordinator.requestLocation();
      await coordinator.requestCamera();
      await coordinator.requestPhotos();
      expect(locationCalls, 1);
      expect(cameraCalls, 1);
      expect(photosCalls, 1);
    },
  );
}
