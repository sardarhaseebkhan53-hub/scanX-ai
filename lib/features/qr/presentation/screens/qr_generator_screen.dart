import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../services/qr/qr_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../controllers/qr_controller.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'Sardar Haseeb Website');
  final TextEditingController _contentController = TextEditingController(text: 'https://sardarhaseeb.com');
  String _selectedType = 'url';
  Color _qrColor = const Color(0xFF2563EB); // Royal Blue default
  bool _includeCenterLogo = true;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(qrProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Generate QR & Barcode',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(
              _includeCenterLogo ? Icons.verified_rounded : Icons.verified_outlined,
              color: _includeCenterLogo ? Colors.amber : null,
            ),
            tooltip: 'Toggle Center Logo Badge',
            onPressed: () => setState(() => _includeCenterLogo = !_includeCenterLogo),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Preview Card with Real QrImageView & Custom Color / Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _qrColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _qrColor.withOpacity(0.3)),
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
                    child: _selectedType == 'barcode'
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            child: Column(
                              children: [
                                Icon(Icons.view_column_rounded, size: 84, color: _qrColor),
                                const SizedBox(height: 8),
                                Text(
                                  _contentController.text,
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 3,
                                    color: _qrColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: _contentController.text.isEmpty
                                    ? 'https://sardarhaseeb.com'
                                    : _contentController.text,
                                version: QrVersions.auto,
                                size: 165,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: _qrColor,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: _qrColor,
                                ),
                              ),
                              if (_includeCenterLogo)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                    border: Border.all(color: _qrColor, width: 2),
                                  ),
                                  child: Icon(Icons.workspace_premium_rounded, color: _qrColor, size: 20),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _titleController.text.isEmpty ? 'Code Title' : _titleController.text,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${_selectedType.toUpperCase()} (${_selectedType == "barcode" ? "EAN-13 / Code 128" : "2D Matrix"})',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Custom Color Selector (Dark Blue, Emerald Green, Purple, Red, Amber, Black)
            const Text(
              'Customize QR Color System',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildColorCircle(const Color(0xFF2563EB), 'Royal Blue'),
                _buildColorCircle(const Color(0xFF10B981), 'Emerald'),
                _buildColorCircle(const Color(0xFF8B5CF6), 'Purple'),
                _buildColorCircle(const Color(0xFFEF4444), 'Red'),
                _buildColorCircle(const Color(0xFFF59E0B), 'Amber'),
                _buildColorCircle(const Color(0xFF0F172A), 'Obsidian'),
              ],
            ),
            const SizedBox(height: 20),

            // 3. QR & Barcode Type Chips (All 10 Types)
            const Text(
              'Select Code Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip('Website URL', 'url'),
                  _buildTypeChip('Barcode (EAN/Code128)', 'barcode'),
                  _buildTypeChip('vCard Contact', 'contact'),
                  _buildTypeChip('Event (iCal)', 'event'),
                  _buildTypeChip('Paste Clipboard', 'clipboard'),
                  _buildTypeChip('Email Address', 'email'),
                  _buildTypeChip('Phone Number', 'phone'),
                  _buildTypeChip('SMS Message', 'sms'),
                  _buildTypeChip('Location Map', 'location'),
                  _buildTypeChip('Plain Text Note', 'text'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Input Fields
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Code Label / Title',
                prefixIcon: Icon(Icons.label_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: (_selectedType == 'text' || _selectedType == 'event') ? 4 : 1,
              decoration: InputDecoration(
                labelText: _getLabelForType(_selectedType),
                prefixIcon: Icon(_getIconForType(_selectedType)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // 5. Save, Print & Share
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      QRService().printQrCard(
                        title: _titleController.text,
                        qrContent: _contentController.text,
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
                      Share.share(_contentController.text, subject: _titleController.text);
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share Payload'),
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
                final content = _contentController.text.trim();
                if (content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter content payload for the code.')),
                  );
                  return;
                }
                controller.generateCustomQr(
                  title: _titleController.text.trim().isEmpty ? 'Custom Code' : _titleController.text.trim(),
                  rawContent: content,
                  type: _selectedType,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved generated ${_selectedType.toUpperCase()} code to Toolkit History!')),
                );
              },
              icon: const Icon(Icons.check_rounded),
              label: Text('Save ${_selectedType.toUpperCase()} to Toolkit'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color, String label) {
    final isSelected = _qrColor == color;
    return GestureDetector(
      onTap: () => setState(() => _qrColor = color),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.amber, width: 3)
              : Border.all(color: Colors.grey.withOpacity(0.3)),
          boxShadow: isSelected ? const [BoxShadow(color: Colors.black26, blurRadius: 6)] : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
      ),
    );
  }

  Widget _buildTypeChip(String label, String type) {
    final isSelected = _selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) async {
          setState(() {
            _selectedType = type;
            if (type == 'contact') {
              _contentController.text = QRService().buildVCardString(
                name: 'Sardar Haseeb',
                org: 'Sardar Haseeb Technologies',
                email: 'support@sardarhaseeb.com',
                phone: '+1-800-555-0199',
                url: 'https://sardarhaseeb.com',
              );
            } else if (type == 'event') {
              _titleController.text = 'ScanX AI Executive Review';
              _contentController.text =
                  'BEGIN:VEVENT\nSUMMARY:ScanX AI Executive Review\nDTSTART:20260810T090000Z\nDTEND:20260810T100000Z\nLOCATION:Islamabad HQ\nEND:VEVENT';
            } else if (type == 'barcode') {
              _contentController.text = '9780201379624'; // Standard ISBN / EAN-13 sample
            } else if (type == 'url') {
              _contentController.text = 'https://sardarhaseeb.com';
            } else if (type == 'email') {
              _contentController.text = 'support@sardarhaseeb.com';
            } else if (type == 'phone') {
              _contentController.text = '+1-800-555-0199';
            } else if (type == 'location') {
              _contentController.text = 'geo:33.6844,73.0479'; // Islamabad coordinates
            }
          });

          if (type == 'clipboard') {
            final data = await Clipboard.getData(Clipboard.kTextPlain);
            final text = data?.text ?? 'https://sardarhaseeb.com';
            setState(() {
              _titleController.text = 'Clipboard Content QR';
              _contentController.text = text;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pasted text from device clipboard!')),
              );
            }
          }
        },
      ),
    );
  }

  String _getLabelForType(String type) {
    switch (type) {
      case 'url':
        return 'Website Link (https://...)';
      case 'barcode':
        return 'Linear Barcode Number (EAN-13 / Code 128 / UPC-A)';
      case 'event':
        return 'Calendar Event Payload (BEGIN:VEVENT...)';
      case 'clipboard':
        return 'Pasted Clipboard Payload';
      case 'email':
        return 'Email Address';
      case 'phone':
        return 'Phone Number (+...)';
      case 'sms':
        return 'SMS Destination & Text';
      case 'contact':
        return 'vCard Content Payload';
      case 'location':
        return 'Geo Coordinates (geo:lat,lng)';
      default:
        return 'Plain Text / Note';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'url':
        return Icons.language_rounded;
      case 'barcode':
        return Icons.view_column_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'clipboard':
        return Icons.content_paste_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'sms':
        return Icons.sms_rounded;
      case 'contact':
        return Icons.person_pin_rounded;
      case 'location':
        return Icons.location_on_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }
}
