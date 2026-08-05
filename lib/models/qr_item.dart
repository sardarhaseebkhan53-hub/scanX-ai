import 'package:equatable/equatable.dart';

enum QRType {
  url,
  wifi,
  email,
  phone,
  sms,
  contact,
  location,
  text,
  barcode,
  payment,
}

class QRItem extends Equatable {
  final String id;
  final String title;
  final String rawContent;
  final String type; // 'url', 'wifi', 'email', 'phone', 'sms', 'contact', 'location', 'text', 'barcode', 'payment'
  final bool isFavorite;
  final DateTime createdAt;
  final String? wifiSsid;
  final String? wifiPassword;
  final String? wifiSecurity; // 'WPA/WPA2', 'WPA3', 'WEP', 'Open'
  final bool isHiddenNetwork;
  final bool isSafeUrl;

  const QRItem({
    required this.id,
    required this.title,
    required this.rawContent,
    this.type = 'text',
    this.isFavorite = false,
    required this.createdAt,
    this.wifiSsid,
    this.wifiPassword,
    this.wifiSecurity = 'WPA/WPA2',
    this.isHiddenNetwork = false,
    this.isSafeUrl = true,
  });

  QRItem copyWith({
    String? id,
    String? title,
    String? rawContent,
    String? type,
    bool? isFavorite,
    DateTime? createdAt,
    String? wifiSsid,
    String? wifiPassword,
    String? wifiSecurity,
    bool? isHiddenNetwork,
    bool? isSafeUrl,
  }) {
    return QRItem(
      id: id ?? this.id,
      title: title ?? this.title,
      rawContent: rawContent ?? this.rawContent,
      type: type ?? this.type,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      wifiSsid: wifiSsid ?? this.wifiSsid,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      wifiSecurity: wifiSecurity ?? this.wifiSecurity,
      isHiddenNetwork: isHiddenNetwork ?? this.isHiddenNetwork,
      isSafeUrl: isSafeUrl ?? this.isSafeUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'rawContent': rawContent,
      'type': type,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
      'wifiSsid': wifiSsid,
      'wifiPassword': wifiPassword,
      'wifiSecurity': wifiSecurity,
      'isHiddenNetwork': isHiddenNetwork,
      'isSafeUrl': isSafeUrl,
    };
  }

  factory QRItem.fromMap(Map<dynamic, dynamic> map) {
    return QRItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Scanned Code',
      rawContent: map['rawContent'] as String? ?? '',
      type: map['type'] as String? ?? 'text',
      isFavorite: map['isFavorite'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      wifiSsid: map['wifiSsid'] as String?,
      wifiPassword: map['wifiPassword'] as String?,
      wifiSecurity: map['wifiSecurity'] as String? ?? 'WPA/WPA2',
      isHiddenNetwork: map['isHiddenNetwork'] as bool? ?? false,
      isSafeUrl: map['isSafeUrl'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        rawContent,
        type,
        isFavorite,
        createdAt,
        wifiSsid,
        wifiPassword,
        wifiSecurity,
        isHiddenNetwork,
        isSafeUrl,
      ];
}
