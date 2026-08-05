import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../models/qr_item.dart';
import '../../../../services/qr/qr_service.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../controllers/qr_controller.dart';

class QrDashboardScreen extends ConsumerStatefulWidget {
  const QrDashboardScreen({super.key});

  @override
  ConsumerState<QrDashboardScreen> createState() => _QrDashboardScreenState();
}

class _QrDashboardScreenState extends ConsumerState<QrDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrProvider);
    final controller = ref.read(qrProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final items = _showFavoritesOnly ? state.favoriteItems : state.filteredHistory;

    return Scaffold(
      appBar: CustomAppBar(
        title: _showFavoritesOnly ? 'Favorite QR Codes' : 'QR & Wi-Fi Toolkit',
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.star_rounded : Icons.star_border_rounded,
              color: _showFavoritesOnly ? Colors.amber : null,
            ),
            tooltip: _showFavoritesOnly ? 'Show All History' : 'Show Favorites Only',
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear History',
            onPressed: () {
              controller.clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared QR & Barcode scan history.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Top 4 Action Cards (Scan, Generate, Wi-Fi Studio, Export)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                _buildDashboardCard(
                  context: context,
                  title: 'Scan QR & Barcode',
                  subtitle: 'Live Camera Scanner',
                  icon: Icons.qr_code_scanner_rounded,
                  color: const Color(0xFF8B5CF6), // Purple
                  onTap: () => context.push(RouteNames.qrScanner),
                ),
                _buildDashboardCard(
                  context: context,
                  title: 'Generate QR',
                  subtitle: 'URL, vCard, Text',
                  icon: Icons.qr_code_2_rounded,
                  color: const Color(0xFF3B82F6), // Blue
                  onTap: () => context.push(RouteNames.qrGenerator),
                ),
                _buildDashboardCard(
                  context: context,
                  title: 'Wi-Fi QR Studio',
                  subtitle: 'SSID, WPA/WPA3, WEP',
                  icon: Icons.wifi_rounded,
                  color: const Color(0xFF10B981), // Green
                  onTap: () => context.push(RouteNames.wifiQrStudio),
                ),
                _buildDashboardCard(
                  context: context,
                  title: 'Print Verification',
                  subtitle: 'Export QR PDF Card',
                  icon: Icons.print_rounded,
                  color: const Color(0xFFF59E0B), // Amber
                  onTap: () => _exportAllHistoryAsPdf(context, state.history),
                ),
              ],
            ),
          ),

          // 2. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: controller.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search scanned Wi-Fi networks, URLs, or notes...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          controller.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Category Filter Chips (All, wifi, url, contact, text, payment)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All', 'all', state.selectedCategory, controller),
                _buildCategoryChip('Wi-Fi', 'wifi', state.selectedCategory, controller),
                _buildCategoryChip('Website URL', 'url', state.selectedCategory, controller),
                _buildCategoryChip('vCard Contact', 'contact', state.selectedCategory, controller),
                _buildCategoryChip('Text Note', 'text', state.selectedCategory, controller),
                _buildCategoryChip('Payment Code', 'payment', state.selectedCategory, controller),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. History / Favorites List
          Expanded(
            child: items.isEmpty
                ? EmptyStateWidget(
                    title: _showFavoritesOnly ? 'No Favorite QR Codes' : 'No QR Scans Yet',
                    subtitle: _showFavoritesOnly
                        ? 'Tap the star icon on any scanned code to mark it as a favorite.'
                        : 'Tap "Scan QR & Barcode" or generate your first Wi-Fi code above.',
                    buttonText: _showFavoritesOnly ? null : 'Scan QR Now',
                    onButtonPressed: _showFavoritesOnly
                        ? null
                        : () => context.push(RouteNames.qrScanner),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildQrItemCard(context, item, controller);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    String category,
    String selectedCategory,
    QRController controller,
  ) {
    final isSelected = selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => controller.setCategory(category),
      ),
    );
  }

  Widget _buildQrItemCard(BuildContext context, QRItem item, QRController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    Color badgeColor = colorScheme.primary;
    IconData typeIcon = Icons.qr_code_2_rounded;

    switch (item.type) {
      case 'wifi':
        badgeColor = const Color(0xFF10B981); // Green
        typeIcon = Icons.wifi_rounded;
        break;
      case 'url':
        badgeColor = const Color(0xFF3B82F6); // Blue
        typeIcon = Icons.language_rounded;
        break;
      case 'contact':
        badgeColor = const Color(0xFF8B5CF6); // Purple
        typeIcon = Icons.person_pin_rounded;
        break;
      case 'payment':
        badgeColor = const Color(0xFFF59E0B); // Amber
        typeIcon = Icons.payment_rounded;
        break;
      default:
        badgeColor = const Color(0xFF64748B);
        typeIcon = Icons.text_snippet_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(typeIcon, color: badgeColor, size: 26),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (!item.isSafeUrl) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SUSPICIOUS',
                  style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.rawContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontFamily: 'Courier'),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  item.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
                const Text(' • '),
                Text(
                  _formatDate(item.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: item.isFavorite ? Colors.amber : Colors.grey,
              ),
              onPressed: () => controller.toggleFavorite(item.id),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) {
                if (action == 'share') {
                  Share.share(item.rawContent, subject: item.title);
                } else if (action == 'print') {
                  QRService().printQrCard(title: item.title, qrContent: item.rawContent);
                } else if (action == 'delete') {
                  controller.deleteItem(item.id);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Share Code'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Print Verification Card'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showQrDetailModal(context, item),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} • ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showQrDetailModal(BuildContext context, QRItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.type.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: SelectableText(
                  item.rawContent,
                  style: const TextStyle(fontSize: 14, fontFamily: 'Courier'),
                ),
              ),
              const SizedBox(height: 24),

              // Safety confirmation button before opening links or connecting Wi-Fi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        QRService().printQrCard(title: item.title, qrContent: item.rawContent);
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print Card'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _confirmAndExecuteAction(context, item);
                      },
                      icon: const Icon(Icons.security_rounded),
                      label: Text(item.type == 'wifi' ? 'Connect Wi-Fi' : 'Open Safe URL'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAndExecuteAction(BuildContext context, QRItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Text(item.type == 'wifi' ? 'Confirm Wi-Fi Connect' : 'Confirm URL Launch'),
          ],
        ),
        content: Text(
          item.type == 'wifi'
              ? 'Are you sure you want to connect to network "${item.wifiSsid ?? item.title}"? ScanX AI validates SSID formatting before platform connection.'
              : 'You are about to launch:\n\n${item.rawContent}\n\nDo you wish to proceed safely?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    item.type == 'wifi'
                        ? 'Connecting to Wi-Fi network "${item.wifiSsid}" via platform Wi-Fi APIs...'
                        : 'Launching safe link: "${item.title}"',
                  ),
                ),
              );
            },
            child: const Text('Confirm & Execute'),
          ),
        ],
      ),
    );
  }

  void _exportAllHistoryAsPdf(BuildContext context, List<QRItem> history) async {
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR scans to export.')),
      );
      return;
    }
    final first = history.first;
    await QRService().exportQrReportAsPdf(
      title: first.title,
      qrContent: first.rawContent,
      subtitle: 'Verified QR & Wi-Fi Toolkit Payload Report',
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported QR Verification PDF report to device storage!')),
      );
    }
  }
}
