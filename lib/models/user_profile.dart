import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isPremium;
  final DateTime? subscriptionExpiry;
  final String cloudProvider; // 'firebase', 'google_drive', 'dropbox', 'onedrive'
  final int storageUsedBytes;
  final bool cloudSyncEnabled;

  const UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.isPremium = false,
    this.subscriptionExpiry,
    this.cloudProvider = 'firebase',
    this.storageUsedBytes = 0,
    this.cloudSyncEnabled = true,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    bool? isPremium,
    DateTime? subscriptionExpiry,
    String? cloudProvider,
    int? storageUsedBytes,
    bool? cloudSyncEnabled,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isPremium: isPremium ?? this.isPremium,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      cloudProvider: cloudProvider ?? this.cloudProvider,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'isPremium': isPremium,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'cloudProvider': cloudProvider,
      'storageUsedBytes': storageUsedBytes,
      'cloudSyncEnabled': cloudSyncEnabled,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String? ?? 'local_user',
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      isPremium: map['isPremium'] as bool? ?? false,
      subscriptionExpiry: map['subscriptionExpiry'] != null
          ? DateTime.tryParse(map['subscriptionExpiry'].toString())
          : null,
      cloudProvider: map['cloudProvider'] as String? ?? 'firebase',
      storageUsedBytes: map['storageUsedBytes'] as int? ?? 0,
      cloudSyncEnabled: map['cloudSyncEnabled'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        isPremium,
        subscriptionExpiry,
        cloudProvider,
        storageUsedBytes,
        cloudSyncEnabled,
      ];
}
