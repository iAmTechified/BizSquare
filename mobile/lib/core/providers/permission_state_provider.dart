import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionState {
  final bool isContactsGranted;
  final bool isContactsDenied;
  final bool isContactsPermanentlyDenied;
  final bool isNotificationGranted;

  const PermissionState({
    this.isContactsGranted = false,
    this.isContactsDenied = false,
    this.isContactsPermanentlyDenied = false,
    this.isNotificationGranted = false,
  });

  PermissionState copyWith({
    bool? isContactsGranted,
    bool? isContactsDenied,
    bool? isContactsPermanentlyDenied,
    bool? isNotificationGranted,
  }) {
    return PermissionState(
      isContactsGranted: isContactsGranted ?? this.isContactsGranted,
      isContactsDenied: isContactsDenied ?? this.isContactsDenied,
      isContactsPermanentlyDenied: isContactsPermanentlyDenied ?? this.isContactsPermanentlyDenied,
      isNotificationGranted: isNotificationGranted ?? this.isNotificationGranted,
    );
  }
}

final permissionStateProvider = StateNotifierProvider<PermissionStateNotifier, PermissionState>((ref) {
  return PermissionStateNotifier();
});

class PermissionStateNotifier extends StateNotifier<PermissionState> {
  PermissionStateNotifier() : super(const PermissionState()) {
    checkAllPermissions();
  }

  Future<void> checkAllPermissions() async {
    try {
      final contactStatus = await Permission.contacts.status;
      final notifStatus = await Permission.notification.status;

      state = state.copyWith(
        isContactsGranted: contactStatus.isGranted,
        isContactsDenied: contactStatus.isDenied,
        isContactsPermanentlyDenied: contactStatus.isPermanentlyDenied,
        isNotificationGranted: notifStatus.isGranted,
      );
    } catch (_) {
      // Fallback
    }
  }

  Future<bool> requestContactsPermission() async {
    try {
      final status = await Permission.contacts.request();
      final isGranted = status.isGranted;
      state = state.copyWith(
        isContactsGranted: isGranted,
        isContactsDenied: status.isDenied,
        isContactsPermanentlyDenied: status.isPermanentlyDenied,
      );
      return isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      final isGranted = status.isGranted;
      state = state.copyWith(isNotificationGranted: isGranted);
      return isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
