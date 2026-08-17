import 'package:permission_handler/permission_handler.dart';

typedef PermissionRequest = Future<PermissionStatus> Function();

class PermissionCoordinator {
  PermissionCoordinator({
    PermissionRequest? requestLocation,
    PermissionRequest? requestCamera,
  }) : _requestLocation =
           requestLocation ?? Permission.locationWhenInUse.request,
       _requestCamera = requestCamera ?? Permission.camera.request;

  static final PermissionCoordinator instance = PermissionCoordinator();

  final PermissionRequest _requestLocation;
  final PermissionRequest _requestCamera;

  Future<PermissionStatus> requestLocation() => _requestLocation();

  Future<PermissionStatus> requestCamera() => _requestCamera();
}
