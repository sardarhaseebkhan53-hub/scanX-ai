import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../config/injection/injection_container.dart';
import '../../../../services/storage/local_storage_service.dart';

/// State for the user profile picture and display name.
class UserProfileState {
  final String? displayName;
  final String? avatarPath; // local file path to picked image
  final bool isLoggedIn;

  const UserProfileState({
    this.displayName,
    this.avatarPath,
    this.isLoggedIn = false,
  });

  UserProfileState copyWith({
    String? displayName,
    String? avatarPath,
    bool? isLoggedIn,
  }) {
    return UserProfileState(
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class UserProfileController extends StateNotifier<UserProfileState> {
  final ImagePicker _picker = ImagePicker();
  final LocalStorageService _localStorage;

  UserProfileController({LocalStorageService? localStorage})
      : _localStorage = localStorage ?? sl<LocalStorageService>(),
        super(const UserProfileState()) {
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    try {
      final settings = await _localStorage.getSettings();
      // In a real app this would load from Firebase Auth or local profile store.
      // For now we just load any previously saved avatar path from settings or prefs.
      state = state.copyWith(
        displayName: null, // No user logged in by default
        isLoggedIn: false,
      );
    } catch (_) {}
  }

  /// Log in with a display name (simulated for UI).
  void setLoggedIn(String name, {String? avatarUrl}) {
    state = state.copyWith(
      displayName: name,
      isLoggedIn: true,
    );
  }

  /// Log out.
  void logOut() {
    state = const UserProfileState();
  }

  /// Pick a new profile picture from the device gallery and persist it locally.
  Future<void> pickAvatarFromGallery() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (xFile == null) return;

      // Copy to app documents dir so it persists across restarts.
      final dir = await getApplicationDocumentsDirectory();
      final saved = File('${dir.path}/profile_avatar.jpg');
      await File(xFile.path).copy(saved.path);

      state = state.copyWith(avatarPath: saved.path);
    } catch (_) {
      // Silently fail — user can retry.
    }
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileController, UserProfileState>((ref) {
  return UserProfileController();
});
