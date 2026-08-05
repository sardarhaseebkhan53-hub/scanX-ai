import 'package:flutter/material.dart';
import '../../../../models/watermark_config.dart';

class WatermarkStudioModal extends StatefulWidget {
  final WatermarkConfig initialConfig;
  final ValueChanged<WatermarkConfig> onApply;

  const WatermarkStudioModal({
    super.key,
    required this.initialConfig,
    required this.onApply,
  });

  static void show(
    BuildContext context, {
    required WatermarkConfig initialConfig,
    required ValueChanged<WatermarkConfig> onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WatermarkStudioModal(
        initialConfig: initialConfig,
        onApply: onApply,
      ),
    );
  }

  @override
  State<WatermarkStudioModal> createState() => _WatermarkStudioModalState();
}

class _WatermarkStudioModalState extends State<WatermarkStudioModal> {
  late WatermarkConfig _config;
  late TextEditingController _customTextController;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    _customTextController = TextEditingController(text: _config.customText);
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar & title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Watermark Studio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _config.isEnabled,
                  onChanged: (val) => setState(() => _config = _config.copyWith(isEnabled: val)),
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Live Preview Card
                  const Text(
                    'Live Watermark Preview',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: _config.isEnabled
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.water_drop_rounded,
                                  color: colorScheme.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _config.buildFormattedText(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Text(
                              'Watermark disabled. Scans will export without footer watermark.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  if (_config.isEnabled) ...[
                    // 2. Custom Text Input
                    TextField(
                      controller: _customTextController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Note or Company Reference',
                        hintText: 'e.g. Sardar Haseeb Technologies',
                      ),
                      onChanged: (val) {
                        setState(() => _config = _config.copyWith(customText: val));
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Automated Checkbox Items
                    const Text(
                      'Automatic Footer Options',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    _buildCheckbox(
                      label: 'Scanned with ScanX AI (App Name)',
                      value: _config.includeAppName,
                      onChanged: (val) =>
                          setState(() => _config = _config.copyWith(includeAppName: val)),
                    ),
                    _buildCheckbox(
                      label: 'Developed by Sardar Haseeb (Developer)',
                      value: _config.includeDeveloperName,
                      onChanged: (val) =>
                          setState(() => _config = _config.copyWith(includeDeveloperName: val)),
                    ),
                    _buildCheckbox(
                      label: 'Current Date & Timestamp',
                      value: _config.includeDate,
                      onChanged: (val) =>
                          setState(() => _config = _config.copyWith(includeDate: val)),
                    ),
                    _buildCheckbox(
                      label: 'Unique Scan ID',
                      value: _config.includeScanId,
                      onChanged: (val) =>
                          setState(() => _config = _config.copyWith(includeScanId: val)),
                    ),
                    _buildCheckbox(
                      label: 'Embed QR Code Verification Badge',
                      value: _config.includeQrCode,
                      onChanged: (val) =>
                          setState(() => _config = _config.copyWith(includeQrCode: val)),
                    ),
                    const SizedBox(height: 20),

                    // 4. Position Selector
                    const Text(
                      'Watermark Position',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildPositionChip('Bottom Right', 'bottomRight'),
                        _buildPositionChip('Bottom Left', 'bottomLeft'),
                        _buildPositionChip('Top Right', 'topRight'),
                        _buildPositionChip('Top Left', 'topLeft'),
                        _buildPositionChip('Center Overlay', 'center'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 5. Opacity Slider
                    Text(
                      'Opacity: ${(_config.opacity * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Slider(
                      value: _config.opacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      activeColor: colorScheme.primary,
                      onChanged: (val) {
                        setState(() => _config = _config.copyWith(opacity: val));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {
                        widget.onApply(_config);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Apply Watermark'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }

  Widget _buildPositionChip(String label, String position) {
    final isSelected = _config.position == position;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _config = _config.copyWith(position: position)),
    );
  }
}
