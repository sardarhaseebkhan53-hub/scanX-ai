import 'package:equatable/equatable.dart';

class DocumentItem extends Equatable {
  final String id;
  final String title;
  final String? folderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> filePaths;
  final String pdfPath;
  final String? ocrText;
  final List<String> tags;
  final bool isFavorite;
  final bool isLocked;
  final bool isPinned;
  final bool isArchived;
  final bool isTrashed;
  final int pageCount;
  final int fileSizeBytes;
  final String? aiSummary;
  final Map<String, dynamic>? aiMetadata;

  const DocumentItem({
    required this.id,
    required this.title,
    this.folderId,
    required this.createdAt,
    required this.updatedAt,
    required this.filePaths,
    required this.pdfPath,
    this.ocrText,
    this.tags = const [],
    this.isFavorite = false,
    this.isLocked = false,
    this.isPinned = false,
    this.isArchived = false,
    this.isTrashed = false,
    this.pageCount = 1,
    this.fileSizeBytes = 0,
    this.aiSummary,
    this.aiMetadata,
  });

  DocumentItem copyWith({
    String? id,
    String? title,
    String? folderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? filePaths,
    String? pdfPath,
    String? ocrText,
    List<String>? tags,
    bool? isFavorite,
    bool? isLocked,
    bool? isPinned,
    bool? isArchived,
    bool? isTrashed,
    int? pageCount,
    int? fileSizeBytes,
    String? aiSummary,
    Map<String, dynamic>? aiMetadata,
  }) {
    return DocumentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      folderId: folderId ?? this.folderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      filePaths: filePaths ?? this.filePaths,
      pdfPath: pdfPath ?? this.pdfPath,
      ocrText: ocrText ?? this.ocrText,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isTrashed: isTrashed ?? this.isTrashed,
      pageCount: pageCount ?? this.pageCount,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      aiSummary: aiSummary ?? this.aiSummary,
      aiMetadata: aiMetadata ?? this.aiMetadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'folderId': folderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'filePaths': filePaths,
      'pdfPath': pdfPath,
      'ocrText': ocrText,
      'tags': tags,
      'isFavorite': isFavorite,
      'isLocked': isLocked,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'isTrashed': isTrashed,
      'pageCount': pageCount,
      'fileSizeBytes': fileSizeBytes,
      'aiSummary': aiSummary,
      'aiMetadata': aiMetadata,
    };
  }

  factory DocumentItem.fromMap(Map<dynamic, dynamic> map) {
    return DocumentItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Scan',
      folderId: map['folderId'] as String?,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      filePaths: (map['filePaths'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      pdfPath: map['pdfPath'] as String? ?? '',
      ocrText: map['ocrText'] as String?,
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isFavorite: map['isFavorite'] as bool? ?? false,
      isLocked: map['isLocked'] as bool? ?? false,
      isPinned: map['isPinned'] as bool? ?? false,
      isArchived: map['isArchived'] as bool? ?? false,
      isTrashed: map['isTrashed'] as bool? ?? false,
      pageCount: map['pageCount'] as int? ?? 1,
      fileSizeBytes: map['fileSizeBytes'] as int? ?? 0,
      aiSummary: map['aiSummary'] as String?,
      aiMetadata: map['aiMetadata'] != null
          ? Map<String, dynamic>.from(map['aiMetadata'] as Map)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        folderId,
        createdAt,
        updatedAt,
        filePaths,
        pdfPath,
        ocrText,
        tags,
        isFavorite,
        isLocked,
        isPinned,
        isArchived,
        isTrashed,
        pageCount,
        fileSizeBytes,
        aiSummary,
        aiMetadata,
      ];
}
