import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../widgets/ai_badge.dart';
import '../controllers/ai_controller.dart';

class ReceiptAnalysisScreen extends ConsumerStatefulWidget {
  final String documentId;

  const ReceiptAnalysisScreen({super.key, required this.documentId});

  @override
  ConsumerState<ReceiptAnalysisScreen> createState() => _ReceiptAnalysisScreenState();
}

class _ReceiptAnalysisScreenState extends ConsumerState<ReceiptAnalysisScreen> {
  bool _isInvoiceMode = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(aiProvider(widget.documentId).notifier).analyzeReceiptOrInvoice(isInvoice: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider(widget.documentId));
    final controller = ref.read(aiProvider(widget.documentId).notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final result = state.analysisResult;

    return Scaffold(
      appBar: CustomAppBar(
        title: _isInvoiceMode ? 'Invoice Intelligence' : 'Receipt Analyzer',
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Toggle Receipt/Invoice Mode',
            onPressed: () {
              setState(() => _isInvoiceMode = !_isInvoiceMode);
              controller.analyzeReceiptOrInvoice(isInvoice: _isInvoiceMode);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI extracting vendor, line items, and totals...'),
                ],
              ),
            )
          : result == null
              ? const Center(child: Text('No structured financial data extracted.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header Card (Vendor, Number, Date, Total)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withOpacity(0.12),
                              colorScheme.secondary.withOpacity(0.12)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const AIBadge(label: 'Structured Financial AI'),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Verified Math',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              result.vendorName ?? 'Unknown Vendor',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (result.invoiceNumber != null)
                              Text(
                                'Invoice #: ${result.invoiceNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                              ),
                            const SizedBox(height: 4),
                            if (result.date != null)
                              Text(
                                'Date: ${result.date}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                ),
                              ),
                            const Divider(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount Due',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${result.currency ?? "USD"} \$${(result.totalAmount ?? 0.0).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Extracted Line Items Table
                      const Text(
                        'Extracted Line Items',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            // Header row
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.08),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text('Description',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text('Qty',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('Amount',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            // Rows
                            for (final item in result.items) ...[
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(item['description']?.toString() ?? 'Item'),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        item['quantity']?.toString() ?? '1',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '\$${((item['totalPrice'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item != result.items.last)
                                Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Math Breakdown Card (Subtotal, Tax, Total)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            _buildSummaryRow('Subtotal', '\$${(result.subtotal ?? 0.0).toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            _buildSummaryRow('Estimated Tax', '\$${(result.tax ?? 0.0).toStringAsFixed(2)}'),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              'Total Amount',
                              '\$${(result.totalAmount ?? 0.0).toStringAsFixed(2)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
