import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/injection/injection_container.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../../models/document_item.dart';
import '../controllers/scanner_controller.dart';
import '../../../../widgets/edge_detection_overlay.dart';

// ---------------------------------------------------------------------------
// Scan mode metadata — drives the horizontal AI scan-mode carousel.
// ---------------------------------------------------------------------------

class _ScanModeMeta {
  final ScanMode mode;
  final String label;
  final IconData icon;
  const _ScanModeMeta(this.mode, this.label, this.icon);
}

const List<_ScanModeMeta> _modeMetas = [
  _ScanModeMeta(ScanMode.document, 'Document', Icons.document_scanner_rounded),
  _ScanModeMeta(ScanMode.book, 'Book', Icons.menu_book_rounded),
  _ScanModeMeta(ScanMode.idCard, 'ID Card', Icons.badge_rounded),
  _ScanModeMeta(ScanMode.passport, 'Passport', Icons.credit_card_rounded),
  _ScanModeMeta(ScanMode.receipt, 'Receipt', Icons.receipt_long_rounded),
  _ScanModeMeta(ScanMode.qr, 'QR Code', Icons.qr_code_rounded),
  _ScanModeMeta(ScanMode.photo, 'Photo', Icons.photo_camera_rounded),
  _ScanModeMeta(ScanMode.objectAi, 'Object AI', Icons.auto_awesome_rounded),
  _ScanModeMeta(ScanMode.homework, 'Homework', Icons.school_rounded),
  _ScanModeMeta(ScanMode.businessCard, 'Business', Icons.contact_phone_rounded),
  _ScanModeMeta(ScanMode.whiteboard, 'Whiteboard', Icons.whiteboard_rounded),
  _ScanModeMeta(ScanMode.more, 'More', Icons.grid_view_rounded),
];

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanLineCtrl;
  Offset? _focusPoint;
  bool _focusVisible = false;
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _focusTimer?.cancel();
    super.dispose();
  }

  // --- Live preview color grade (approximation of the selected filter) -----
  ColorFilter? _liveFilter(ColorFilterMode mode) {
    switch (mode) {
      case ColorFilterMode.blackAndWhite:
      case ColorFilterMode.grayscale:
      case ColorFilterMode.signature:
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterMode.color:
      case ColorFilterMode.autoEnhanced:
      case ColorFilterMode.aiEnhance:
      case ColorFilterMode.magazine:
        return const ColorFilter.matrix(<double>[
          1.10, 0, 0, 0, 0,
          0, 1.10, 0, 0, 0,
          0, 0, 1.25, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorFilterMode.highContrast:
        return const ColorFilter.matrix(<double>[
          1.30, 0, 0, 0, -0.10,
          0, 1.30, 0, 0, -0.10,
          0, 0, 1.30, 0, -0.10,
          0, 0, 0, 1, 0,
        ]);
      default:
        return null;
    }
  }

  // --- Mode-specific camera behaviour --------------------------------------
  void _applyMode(ScanMode mode) {
    final ctrl = ref.read(scannerProvider.notifier);
    ctrl.setScanMode(mode);
    switch (mode) {
      case ScanMode.receipt:
      case ScanMode.invoice:
        ctrl.setColorFilter(ColorFilterMode.receipt);
        break;
      case ScanMode.book:
      case ScanMode.document:
        ctrl.setColorFilter(ColorFilterMode.autoEnhanced);
        break;
      case ScanMode.passport:
      case ScanMode.idCard:
        ctrl.setColorFilter(ColorFilterMode.passport);
        break;
      case ScanMode.whiteboard:
        ctrl.setColorFilter(ColorFilterMode.highContrast);
        break;
      case ScanMode.photo:
        ctrl.setColorFilter(ColorFilterMode.photo);
        break;
      default:
        ctrl.setColorFilter(ColorFilterMode.autoEnhanced);
        break;
    }
  }

  // --- AI contextual suggestions ------------------------------------------
  List<String> _suggestions(ScannerState s) {
    final out = <String>[];
    switch (s.currentMode) {
      case ScanMode.document:
        out.addAll(['Place on a flat surface', 'Align all 4 edges']);
        break;
      case ScanMode.receipt:
        out.addAll(['Smooth wrinkles', 'Avoid shadows']);
        break;
      case ScanMode.book:
        out.addAll(['Hold book flat', 'Avoid page curve']);
        break;
      case ScanMode.idCard:
        out.addAll(['Fill the frame', 'Even lighting']);
        break;
      case ScanMode.passport:
        out.add('Capture the photo page');
        break;
      case ScanMode.businessCard:
        out.add('Center the card');
        break;
      case ScanMode.whiteboard:
        out.add('Face the board directly');
        break;
      case ScanMode.photo:
        out.add('Tap anywhere to focus');
        break;
      case ScanMode.objectAi:
        out.add('Open AI Assistant to identify');
        break;
      case ScanMode.homework:
        out.add('Capture the full question');
        break;
      case ScanMode.qr:
        out.add('Align QR inside the frame');
        break;
      default:
        break;
    }
    if (s.isBlurDetected) out.add('Hold steady — blur detected');
    if (s.isHdrOn) out.add('HDR enhanced');
    return out;
  }

  void _showFocusRing(Offset normalized) {
    setState(() {
      _focusPoint = normalized;
      _focusVisible = true;
    });
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _focusVisible = false);
    });
  }

  // --- Capture flow --------------------------------------------------------
  Future<void> _onCapture() async {
    final state = ref.read(scannerProvider);
    final ctrl = ref.read(scannerProvider.notifier);

    if (state.currentMode == ScanMode.qr) {
      if (context.mounted) context.push(RouteNames.qrScanner);
      return;
    }

    final path = await ctrl.capturePhoto();
    if (path == null || !context.mounted) return;

    String finalPath = path;
    if (state.isHdrOn) {
      final enhanced = await ctrl.applyFilterToFile(path, ColorFilterMode.aiEnhance);
      if (enhanced != null && context.mounted) finalPath = enhanced;
    }
    if (context.mounted) context.push(RouteNames.crop, extra: finalPath);
  }

  Future<void> _importGallery() async {
    final ctrl = ref.read(scannerProvider.notifier);
    await ctrl.importFromGallery();
    final images = ref.read(scannerProvider).capturedImages;
    if (images.isNotEmpty && context.mounted) {
      context.push(RouteNames.scanPreview, extra: images);
    }
  }

  Future<void> _importPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;
      final file = File(path);
      final doc = DocumentItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: result.files.first.name.replaceAll('.pdf', ''),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        filePaths: [path],
        pdfPath: path,
        pageCount: 1,
        fileSizeBytes: await file.exists() ? await file.length() : 0,
        tags: const ['Imported PDF'],
      );
      await sl<DocumentRepository>().saveDocument(doc);
      if (context.mounted) context.go(RouteNames.ocrViewer, extra: doc.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _openFilters() {
    final ctrl = ref.read(scannerProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Camera Filters',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _FilterChip(ctrl, 'Auto Enhance', ColorFilterMode.autoEnhanced, Icons.auto_fix_high_rounded),
                _FilterChip(ctrl, 'Original', ColorFilterMode.original, Icons.image_outlined),
                _FilterChip(ctrl, 'Color', ColorFilterMode.color, Icons.palette_rounded),
                _FilterChip(ctrl, 'B&W', ColorFilterMode.blackAndWhite, Icons.invert_colors_rounded),
                _FilterChip(ctrl, 'Grayscale', ColorFilterMode.grayscale, Icons.contrast_rounded),
                _FilterChip(ctrl, 'High Contrast', ColorFilterMode.highContrast, Icons.tonality_rounded),
                _FilterChip(ctrl, 'Magazine', ColorFilterMode.magazine, Icons.menu_book_rounded),
                _FilterChip(ctrl, 'Photo', ColorFilterMode.photo, Icons.photo_camera_rounded),
                _FilterChip(ctrl, 'Receipt', ColorFilterMode.receipt, Icons.receipt_long_rounded),
                _FilterChip(ctrl, 'Passport', ColorFilterMode.passport, Icons.badge_rounded),
                _FilterChip(ctrl, 'Book', ColorFilterMode.book, Icons.book_rounded),
                _FilterChip(ctrl, 'Signature', ColorFilterMode.signature, Icons.draw_rounded),
                _FilterChip(ctrl, 'AI Enhance', ColorFilterMode.aiEnhance, Icons.auto_awesome),
                _FilterChip(ctrl, 'AI Sharpen', ColorFilterMode.aiSharpen, Icons.shutter_speed_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings() {
    final ctrl = ref.read(scannerProvider.notifier);
    final s = ref.read(scannerProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModal) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Camera Settings',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              _SettingRow('Grid', Icons.grid_on_rounded, s.isGridOverlayOn,
                  () { ctrl.toggleGridOverlay(); setModal(() {}); }),
              _SettingRow('Level', Icons.straighten_rounded, s.isLevelIndicatorOn,
                  () { ctrl.toggleLevelIndicator(); setModal(() {}); }),
              _SettingRow('Auto Capture', Icons.auto_awesome_rounded, s.isAutoCaptureEnabled,
                  () { ctrl.toggleAutoCapture(); setModal(() {}); }),
              _SettingRow('Shadow Removal', Icons.light_mode_rounded, s.isShadowRemovalEnabled,
                  () { ctrl.toggleShadowRemoval(); setModal(() {}); }),
              _SettingRow('Lock Exposure', Icons.lock_rounded, s.isExposureLocked,
                  () { ctrl.toggleExposureLock(); setModal(() {}); }),
              _SettingRow('HDR', Icons.hdr_enhanced_select_rounded, s.isHdrOn,
                  () { ctrl.toggleHdr(); setModal(() {}); }),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(RouteNames.pdfTools);
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('PDF Manager'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go(RouteNames.home);
                      },
                      icon: const Icon(Icons.folder_rounded, size: 18),
                      label: const Text('File Manager'),
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(scannerProvider);
    final ctrl = ref.read(scannerProvider.notifier);
    final filter = _liveFilter(s.filterMode);
    final suggestions = _suggestions(s);

    final preview = s.isInitialized && ctrl.cameraController != null
        ? LayoutBuilder(
            builder: (ctx, constraints) => GestureDetector(
              onTapDown: (d) {
                final p = Offset(
                  d.localPosition.dx / constraints.maxWidth,
                  d.localPosition.dy / constraints.maxHeight,
                );
                ctrl.setFocusPoint(p);
                _showFocusRing(p);
              },
              child: filter == null
                  ? CameraPreview(ctrl.cameraController!)
                  : ColorFiltered(
                      colorFilter: filter,
                      child: CameraPreview(ctrl.cameraController!),
                    ),
            ),
          )
        : _FallbackPreview(onImport: _importGallery);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: preview),

          // Vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ),

          // Grid overlay
          if (s.isGridOverlayOn)
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _LuxGridPainter()))),

          // Edge detection + scan line
          Positioned.fill(
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final corners = [
                Offset(w * 0.12, h * 0.20),
                Offset(w * 0.88, h * 0.20),
                Offset(w * 0.90, h * 0.78),
                Offset(w * 0.10, h * 0.78),
              ];
              return Stack(
                children: [
                  EdgeDetectionOverlay(corners: corners, strokeColor: AppColors.neonCyan),
                  AnimatedBuilder(
                    animation: _scanLineCtrl,
                    builder: (context, _) {
                      final top = h * 0.20 + (h * 0.58) * _scanLineCtrl.value;
                      return Positioned(
                        top: top,
                        left: w * 0.14,
                        right: w * 0.14,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.neonCyan.withOpacity(0),
                                AppColors.neonCyan,
                                AppColors.neonCyan.withOpacity(0),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(color: AppColors.neonCyan.withOpacity(0.8), blurRadius: 12, spreadRadius: 1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }),
          ),

          // Tap-to-focus ring
          if (_focusVisible && _focusPoint != null)
            Positioned.fill(
              child: LayoutBuilder(builder: (c, cons) {
                final x = _focusPoint!.dx * cons.maxWidth;
                final y = _focusPoint!.dy * cons.maxHeight;
                return Stack(children: [
                  Positioned(
                    left: x - 26,
                    top: y - 26,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.neonCyan, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ]);
              }),
            ),

          // Level indicator
          if (s.isLevelIndicatorOn)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.47,
              left: MediaQuery.of(context).size.width * 0.34,
              right: MediaQuery.of(context).size.width * 0.34,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: AppColors.neonGreen, blurRadius: 8)],
                ),
              ),
            ),

          // AI quality / lighting / stability badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 96,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: s.isBlurDetected
                      ? AppColors.error.withOpacity(0.92)
                      : Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: s.isBlurDetected ? Colors.redAccent : AppColors.neonGreen.withOpacity(0.4),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: s.isBlurDetected
                            ? Colors.white.withOpacity(0.22)
                            : AppColors.neonGreen.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        s.isBlurDetected ? Icons.warning_amber_rounded : Icons.verified_rounded,
                        color: s.isBlurDetected ? Colors.white : AppColors.neonGreen,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        s.qualityFeedback,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.isBlurDetected ? Colors.white.withOpacity(0.2) : AppColors.neonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_rounded, size: 10, color: s.isBlurDetected ? Colors.white : AppColors.neonGreen),
                          const SizedBox(width: 3),
                          Text(
                            s.isBlurDetected ? 'UNSTABLE' : 'STABLE',
                            style: TextStyle(
                              color: s.isBlurDetected ? Colors.white : AppColors.neonGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top glass navigation bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 360;
                return Row(
                  children: [
                    _GlassBtn(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.42),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: AppColors.neonPurple, size: 14),
                            const SizedBox(width: 6),
                            const Text('AI Camera',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _GlassBtn(
                      icon: _flashIcon(s.flashMode),
                      active: s.flashMode != 'off',
                      onTap: () => ctrl.cycleFlashMode(),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    _GlassBtn(
                      icon: Icons.hdr_enhanced_select_rounded,
                      active: s.isHdrOn,
                      onTap: () => ctrl.toggleHdr(),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    _GlassBtn(icon: Icons.settings_rounded, onTap: _openSettings),
                  ],
                );
              },
            ),
          ),

          // Horizontal AI scan modes carousel
          Positioned(
            top: MediaQuery.of(context).padding.top + 52,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _modeMetas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final meta = _modeMetas[index];
                  final selected = s.currentMode == meta.mode;
                  return GestureDetector(
                    onTap: () => _applyMode(meta.mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.scannerGradient : null,
                        color: selected ? null : Colors.black.withOpacity(0.42),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.12),
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 12)]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(meta.icon, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(meta.label,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Left toolbar
          Positioned(
            left: 14,
            top: MediaQuery.of(context).size.height * 0.30,
            bottom: MediaQuery.of(context).size.height * 0.22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ToolbarBtn(icon: Icons.grid_on_rounded, label: 'Grid', active: s.isGridOverlayOn, onTap: () => ctrl.toggleGridOverlay()),
                _ToolbarBtn(icon: Icons.straighten_rounded, label: 'Level', active: s.isLevelIndicatorOn, onTap: () => ctrl.toggleLevelIndicator()),
                _ToolbarBtn(
                  icon: s.timerSeconds > 0 ? Icons.timer_rounded : Icons.timer_off_rounded,
                  label: s.timerSeconds > 0 ? '${s.timerSeconds}s' : 'Timer',
                  active: s.timerSeconds > 0,
                  onTap: () => ctrl.cycleTimer(),
                ),
                _ToolbarBtn(icon: Icons.document_scanner_rounded, label: 'OCR', onTap: _onCapture),
                _ToolbarBtn(icon: Icons.auto_awesome_rounded, label: 'AI', active: s.isAiAssistOn, onTap: () {
                  ctrl.toggleAiAssist();
                  context.push(RouteNames.aiAssistant);
                }),
              ],
            ),
          ),

          // Right toolbar
          Positioned(
            right: 14,
            top: MediaQuery.of(context).size.height * 0.30,
            bottom: MediaQuery.of(context).size.height * 0.22,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ToolbarBtn(icon: Icons.auto_fix_high_rounded, label: 'Filters', onTap: _openFilters),
                _ToolbarBtn(icon: Icons.auto_awesome, label: 'AI Enh.', active: s.filterMode == ColorFilterMode.aiEnhance, onTap: () => ctrl.setColorFilter(ColorFilterMode.aiEnhance)),
                _ToolbarBtn(icon: Icons.invert_colors_rounded, label: 'B&W', active: s.filterMode == ColorFilterMode.blackAndWhite, onTap: () => ctrl.setColorFilter(ColorFilterMode.blackAndWhite)),
                _ToolbarBtn(icon: Icons.palette_rounded, label: 'Magic', active: s.filterMode == ColorFilterMode.color, onTap: () => ctrl.setColorFilter(ColorFilterMode.color)),
                _ToolbarBtn(icon: Icons.hd_rounded, label: 'HD', active: s.filterMode == ColorFilterMode.aiSharpen, onTap: () => ctrl.setColorFilter(ColorFilterMode.aiSharpen)),
                _ToolbarBtn(icon: Icons.nightlight_round_rounded, label: 'Night', active: s.flashMode == 'torch', onTap: () => ctrl.enableNightMode()),
                _ToolbarBtn(icon: Icons.more_horiz_rounded, label: 'More', onTap: _openSettings),
              ],
            ),
          ),

          // AI suggestions
          if (suggestions.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).size.height * 0.20,
              child: SizedBox(
                height: 30,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.neonPurple.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.neonPurple),
                        const SizedBox(width: 6),
                        Text(suggestions[i],
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls: Gallery · Capture · Import PDF
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _CaptureSideBtn(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: _importGallery,
                ),
                GestureDetector(
                  onTap: s.isCapturing ? null : _onCapture,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE0E0E0)]),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 20, spreadRadius: 1),
                            BoxShadow(color: AppColors.primaryDark.withOpacity(0.45), blurRadius: 32, offset: const Offset(0, 8)),
                          ],
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.scannerGradient,
                          boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.6), blurRadius: 12)],
                        ),
                      ),
                      s.isCapturing
                          ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                          : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                      if (s.timerSeconds > 0)
                        Container(
                          width: 84,
                          height: 84,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                          child: Center(
                            child: Text('${s.timerSeconds}s',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                          ),
                        ),
                    ],
                  ),
                ),
                _CaptureSideBtn(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Import PDF',
                  onTap: _importPdf,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _flashIcon(String mode) {
    switch (mode) {
      case 'on':
        return Icons.flash_on_rounded;
      case 'auto':
        return Icons.flash_auto_rounded;
      case 'torch':
        return Icons.highlight_rounded;
      default:
        return Icons.flash_off_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// Reusable glass buttons
// ---------------------------------------------------------------------------

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _GlassBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: active ? AppColors.scannerGradient : null,
          color: active ? null : Colors.black.withOpacity(0.42),
          shape: BoxShape.circle,
          border: Border.all(color: active ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.16)),
          boxShadow: active ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 12)] : null,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _ToolbarBtn({required this.icon, required this.label, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? AppColors.scannerGradient : null,
          color: active ? null : Colors.black.withOpacity(0.42),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.14)),
          boxShadow: active ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 12)] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CaptureSideBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _CaptureSideBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.14)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10)],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final ScannerController ctrl;
  final String label;
  final ColorFilterMode mode;
  final IconData icon;
  const _FilterChip(this.ctrl, this.label, this.mode, this.icon);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ctrl.setColorFilter(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final VoidCallback onTap;
  const _SettingRow(this.label, this.icon, this.value, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600))),
            Switch(
              value: value,
              activeColor: AppColors.neonPurple,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackPreview extends StatelessWidget {
  final VoidCallback onImport;
  const _FallbackPreview({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0E26), Color(0xFF151D3F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.scannerGradient,
                  boxShadow: [BoxShadow(color: AppColors.primaryDark.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 18),
              const Text('Premium AI Camera Ready', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('AI edge detection • Auto capture • HD', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onImport,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Import from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LuxGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.14)..strokeWidth = 0.8;
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0), Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3), Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
