import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/injection/injection_container.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../models/qr_item.dart';
import '../../../../services/qr/qr_service.dart';
import '../../../../services/storage/secure_storage_service.dart';

class QRState {
  final List<QRItem> history;
  final bool isLoading;
  final String searchQuery;
  final String selectedCategory; // 'all', 'wifi', 'url', 'contact', 'text', 'payment'
  final QRItem? activeGeneratedItem;
  final String? statusMessage;
  final String? errorMessage;

  const QRState({
    this.history = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedCategory = 'all',
    this.activeGeneratedItem,
    this.statusMessage,
    this.errorMessage,
  });

  List<QRItem> get filteredHistory {
    return history.where((item) {
      if (selectedCategory != 'all' && item.type != selectedCategory) {
        return false;
      }
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return item.title.toLowerCase().contains(q) || item.rawContent.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  List<QRItem> get favoriteItems {
    return history.where((item) => item.isFavorite).toList();
  }

  QRState copyWith({
    List<QRItem>? history,
    bool? isLoading,
    String? searchQuery,
    String? selectedCategory,
    QRItem? activeGeneratedItem,
    String? statusMessage,
    String? errorMessage,
  }) {
    return QRState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      activeGeneratedItem: activeGeneratedItem ?? this.activeGeneratedItem,
      statusMessage: statusMessage,
      errorMessage: errorMessage,
    );
  }
}

class QRController extends StateNotifier<QRState> {
  static const String _tag = 'QRController';
  static const String _storageKey = 'scanx_qr_history_v1';
  final QRService _qrService = QRService();
  SecureStorageService? get _secureStorage => sl.isRegistered<SecureStorageService>() ? sl<SecureStorageService>() : null;

  QRController() : super(const QRState(isLoading: true)) {
    unawaited(_loadHistory());
  }

  Future<void> _loadHistory() async {
    try {
      final raw = await _secureStorage?.readSecret(_storageKey);
      final decoded = raw == null ? <dynamic>[] : jsonDecode(raw) as List<dynamic>;
      final items = decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(QRItem.fromMap)
          .where((item) => item.rawContent.trim().isNotEmpty)
          .toList();
      if (!mounted) return;
      state = state.copyWith(history: items, isLoading: false);
    } catch (e) {
      AppLogger.e('Failed to load QR history: $e', tag: _tag);
      if (mounted) state = state.copyWith(isLoading: false, errorMessage: 'Failed to load QR history.');
    }
  }

  Future<void> _persistHistory(List<QRItem> items) async {
    try {
      final trimmed = items.take(250).map((item) => item.toMap()).toList();
      await _secureStorage?.saveSecret(_storageKey, jsonEncode(trimmed));
    } catch (e) {
      AppLogger.e('Failed to save QR history: $e', tag: _tag);
    }
  }

  void _setHistory(List<QRItem> updated, {QRItem? active, String? message}) {
    state = state.copyWith(
      history: updated.take(250).toList(),
      activeGeneratedItem: active,
      statusMessage: message,
    );
    unawaited(_persistHistory(state.history));
  }

  void addScannedItem(String rawContent, {String? title}) {
    final clean = rawContent.trim();
    if (clean.isEmpty) {
      state = state.copyWith(errorMessage: 'No readable QR or barcode content found.');
      return;
    }

    final type = _qrService.detectQRType(clean);
    final safe = _qrService.isUrlSafe(clean);

    final newItem = QRItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title ?? _inferTitleFromContent(clean, type),
      rawContent: clean,
      type: type,
      createdAt: DateTime.now(),
      isSafeUrl: safe,
    );

    final updated = List<QRItem>.from(state.history)..insert(0, newItem);
    _setHistory(
      updated,
      active: newItem,
      message: safe ? 'Scanned $type code successfully!' : '⚠️ Warning: Suspicious URL detected!',
    );
    AppLogger.i('Added scanned QR item: ${newItem.id} ($type)', _tag);
  }

  void generateWifiQr({
    required String ssid,
    required String password,
    String security = 'WPA/WPA2',
    bool isHidden = false,
  }) {
    final raw = _qrService.buildWifiQrString(
      ssid: ssid,
      password: password,
      security: security,
      isHidden: isHidden,
    );

    final item = QRItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Wi-Fi: $ssid',
      rawContent: raw,
      type: 'wifi',
      createdAt: DateTime.now(),
      wifiSsid: ssid,
      wifiPassword: password,
      wifiSecurity: security,
      isHiddenNetwork: isHidden,
    );

    final updated = List<QRItem>.from(state.history)..insert(0, item);
    _setHistory(updated, active: item, message: 'Generated Wi-Fi QR Code for network "$ssid"!');
  }

  void generateCustomQr({
    required String title,
    required String rawContent,
    String? type,
  }) {
    final clean = rawContent.trim();
    if (clean.isEmpty) {
      state = state.copyWith(errorMessage: 'QR content cannot be empty.');
      return;
    }

    final inferredType = type ?? _qrService.detectQRType(clean);
    final item = QRItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty ? _inferTitleFromContent(clean, inferredType) : title.trim(),
      rawContent: clean,
      type: inferredType,
      createdAt: DateTime.now(),
      isSafeUrl: _qrService.isUrlSafe(clean),
    );

    final updated = List<QRItem>.from(state.history)..insert(0, item);
    _setHistory(updated, active: item, message: 'Generated $inferredType QR Code: "${item.title}"!');
  }

  void toggleFavorite(String id) {
    final updated = state.history.map((item) {
      if (item.id == id) {
        return item.copyWith(isFavorite: !item.isFavorite);
      }
      return item;
    }).toList();
    _setHistory(updated);
  }

  void deleteItem(String id) {
    final updated = state.history.where((item) => item.id != id).toList();
    _setHistory(updated);
  }

  void clearHistory() {
    _setHistory([], message: 'Cleared QR & Barcode scan history.');
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  String _inferTitleFromContent(String content, String type) {
    switch (type) {
      case 'wifi':
        return 'Wi-Fi Network Code';
      case 'url':
        return 'Website Link (${content.split("://").last.split("/").first})';
      case 'email':
        return 'Email Address';
      case 'phone':
        return 'Phone Number';
      case 'contact':
        return 'vCard Contact';
      case 'payment':
        return 'Payment Verification Code';
      case 'barcode':
        return 'Barcode ${content.length >= 8 ? content.substring(0, 8) : content}';
      default:
        return 'Plain Text Code';
    }
  }
}

final qrProvider = StateNotifierProvider<QRController, QRState>((ref) {
  return QRController();
});
