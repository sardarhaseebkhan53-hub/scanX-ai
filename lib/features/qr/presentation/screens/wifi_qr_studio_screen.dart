import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../services/qr/qr_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../controllers/qr_controller.dart';

class WifiQrStudioScreen extends ConsumerStatefulWidget {
  const WifiQrStudioScreen({super.key});

  @override
  ConsumerState<WifiQrStudioScreen> createState() => _WifiQrStudioScreenState();
}

class _WifiQrStudioScreenState extends ConsumerState<WifiQrStudioScreen> {
  final TextEditingController _ssidController = TextEditingController(text: 'ScanX_5G_Network');
  final TextEditingController _pwdController = TextEditingController(text: 'EnterpriseSecret');
  String _securityType = 'WPA/WPA2';
  bool _isHidden = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _ssidController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(qrProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final generatedString = QRService().buildWifiQrString(
      ssid: _ssidController.text.trim(),
      password: _pwdController.text,
      security: _securityType,
      isHidden: _isHidden,
    );

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Wi-Fi QR Studio',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Preview Card with Real QrImageView
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primary.withOpacity(0.12), const Color(0xFF10B981).withOpacity(0.12)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: generatedString,
                      version: QrVersions.auto,
                      size: 165,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: colorScheme.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _ssidController.text.isEmpty ? 'Network SSID' : _ssidController.text,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Security: $_securityType ${_isHidden ? "(Hidden Network)" : ""}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      generatedString,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontFamily: 'Courier'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Wi-Fi Configuration Form
            const Text(
              'Network Parameters',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: 'Network Name (SSID)',
                prefixIcon: Icon(Icons.wifi_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pwdController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Network Password',
                prefixIcon: const Icon(Icons.lock_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Security Selector
            ListTile(
              title: const Text('Security Protocol'),
              subtitle: Text('Current: $_securityType'),
              leading: const Icon(Icons.security_rounded),
              trailing: DropdownButton<String>(
                value: _securityType,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'WPA/WPA2', child: Text('WPA / WPA2')),
                  DropdownMenuItem(value: 'WPA3', child: Text('WPA3 Personal')),
                  DropdownMenuItem(value: 'WEP', child: Text('WEP (Legacy)')),
                  DropdownMenuItem(value: 'Open', child: Text('Open Network')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _securityType = val);
                },
              ),
            ),
            SwitchListTile(
              title: const Text('Hidden Network SSID'),
              subtitle: const Text('Network broadcast is disabled'),
              value: _isHidden,
              onChanged: (val) => setState(() => _isHidden = val),
              secondary: const Icon(Icons.visibility_off_outlined),
            ),
            const SizedBox(height: 24),

            // 3. Save, Print & Share Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      QRService().printQrCard(
                        title: 'Wi-Fi: ${_ssidController.text}',
                        qrContent: generatedString,
                      );
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print Card'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Share.share(generatedString, subject: 'Wi-Fi: ${_ssidController.text}');
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
              onPressed: () {
                final ssid = _ssidController.text.trim();
                if (ssid.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a Network Name (SSID).')),
                  );
                  return;
                }
                controller.generateWifiQr(
                  ssid: ssid,
                  password: _pwdController.text,
                  security: _securityType,
                  isHidden: _isHidden,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved Wi-Fi QR Code for "$ssid" to Toolkit History!')),
                );
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save Wi-Fi QR to Toolkit'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
