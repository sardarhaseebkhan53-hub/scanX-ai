import 'package:flutter/material.dart';

import '../../config/injection/injection_container.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/repositories/document_repository.dart';
import '../../models/document_item.dart';

/// Premium bottom sheet that lets the user pick one of their documents.
/// Used by AI Summary, AI Chat, OCR Extract and Receipt Analysis entry points.
class DocumentPickerSheet {
  static Future<DocumentItem?> show(BuildContext context, {String title = 'Choose a Document'}) {
    return showModalBottomSheet<DocumentItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      builder: (ctx) => _PickerBody(title: title),
    );
  }
}

class _PickerBody extends StatefulWidget {
  final String title;
  const _PickerBody({required this.title});

  @override
  State<_PickerBody> createState() => _PickerBodyState();
}

class _PickerBodyState extends State<_PickerBody> {
  late final Future<List<DocumentItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<DocumentRepository>().getDocuments(isTrashed: false).then((docs) {
      docs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: FutureBuilder<List<DocumentItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryDark));
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Could not load documents.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)));
                  }
                  final docs = snap.data ?? [];
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_rounded, color: AppColors.textTertiaryDark, size: 40),
                            const SizedBox(height: 10),
                            Text('No documents yet — scan one first.', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: docs.length > 30 ? 30 : docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context, doc),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.07)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.description_rounded, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(DateFormatter.formatRelative(doc.updatedAt), style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryDark, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
