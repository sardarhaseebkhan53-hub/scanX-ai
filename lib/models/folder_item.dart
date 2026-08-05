import 'package:equatable/equatable.dart';

class FolderItem extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final String colorHex;
  final String iconName;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FolderItem({
    required this.id,
    required this.name,
    this.parentId,
    this.colorHex = '#3B82F6',
    this.iconName = 'folder',
    this.isLocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  FolderItem copyWith({
    String? id,
    String? name,
    String? parentId,
    String? colorHex,
    String? iconName,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FolderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'colorHex': colorHex,
      'iconName': iconName,
      'isLocked': isLocked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FolderItem.fromMap(Map<dynamic, dynamic> map) {
    return FolderItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'New Folder',
      parentId: map['parentId'] as String?,
      colorHex: map['colorHex'] as String? ?? '#3B82F6',
      iconName: map['iconName'] as String? ?? 'folder',
      isLocked: map['isLocked'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        parentId,
        colorHex,
        iconName,
        isLocked,
        createdAt,
        updatedAt,
      ];
}
