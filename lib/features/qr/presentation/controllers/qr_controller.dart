import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../models/qr_item.dart';
import '../../../../services/qr/qr_service.dart';

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
        return item.title.toLowerCase().contains(q) ||
            item.rawContent.toLowerCase().contains(q);
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
  final QRService _qrService = QRService();

  QRController() : super(const QRState()) {
    _loadSampleHistory();
  }

  void _loadSampleHistory() {
    final now = DateTime.now();
    final sampleItems = [
      QRItem(
        id: 'qr_wifi_01',
        title: 'ScanX_Office_Wi-Fi',
        rawContent: _qrService.buildWifiQrString(
          ssid: 'ScanX_Office_5G',
          password: 'SecureEnterprisePassword',
          security: 'WPA/WPA2',
        ),
        type: 'wifi',
        isFavorite: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        wifiSsid: 'ScanX_Office_5G',
        wifiPassword: 'SecureEnterprisePassword',
        wifiSecurity: 'WPA/WPA2',
      ),
      QRItem(
        id: 'qr_url_02',
        title: 'Sardar Haseeb Website',
        rawContent: 'https://sardarhaseeb.com',
        type: 'url',
        isFavorite: true,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      QRItem(
        id: 'qr_contact_03',
        title: 'Sardar Haseeb vCard',
        rawContent: _qrService.buildVCardString(
          name: 'Sardar Haseeb',
          org: 'Sardar Haseeb Technologies',
          email: 'support@sardarhaseeb.com',
          phone: '+1-800-555-0199',
          url: 'https://sardarhaseeb.com',
        ),
        type: 'contact',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    state = state.copyWith(history: sampleItems);
  }

  void addScannedItem(String rawContent, {String? title}) {
    final type = _qrService.detectQRType(rawContent);
    final safe = _qrService.isUrlSafe(rawContent);

    final newItem = QRItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? _inferTitleFromContent(rawContent, type),
      rawContent: rawContent,
      type: type,
      createdAt: DateTime.now(),
      isSafeUrl: safe,
    );

    final updated = List<QRItem>.from(state.history)..insert(0, newItem);
    state = state.copyWith(
      history: updated,
      activeGeneratedItem: newItem,
      statusMessage: safe ? 'Scanned $type code successfully!' : '⚠️ Warning: Suspicious URL detected!',
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
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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
    state = state.copyWith(
      history: updated,
      activeGeneratedItem: item,
      statusMessage: 'Generated Wi-Fi QR Code for network "$ssid"!',
    );
  }

  void generateCustomQr({
    required String title,
    required String rawContent,
    String? type,
  }) {
    final inferredType = type ?? _qrService.detectQRType(rawContent);
    final item = QRItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      rawContent: rawContent,
      type: inferredType,
      createdAt: DateTime.now(),
    );

    final updated = List<QRItem>.from(state.history)..insert(0, item);
    state = state.copyWith(
      history: updated,
      activeGeneratedItem: item,
      statusMessage: 'Generated $inferredType QR Code: "$title"!',
    );
  }

  void toggleFavorite(String id) {
    final updated = state.history.map((item) {
      if (item.id == id) {
        return item.copyWith(isFavorite: !item.isFavorite);
      }
      return item;
    }).toList();
    state = state.copyWith(history: updated);
  }

  void deleteItem(String id) {
    final updated = state.history.where((item) => item.id != id).toList();
    state = state.copyWith(history: updated);
  }

  void clearHistory() {
    state = state.copyWith(
      history: [],
      statusMessage: 'Cleared QR & Barcode scan history.',
    );
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
      default:
        return 'Plain Text Note';
    }
  }
}

final qrProvider = StateNotifierProvider<QRController, QRState>((ref) {
  return QRController();
});
