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
  _ScanModeMeta(ScanMode.whiteboard, 'Whiteboard', Icons.draw_rounded),
  _ScanModeMeta(ScanMode.more, 'More', Icons.grid_view_rounded),
];

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  Offset? _focusPoint;
  bool _focusVisible = false;
  Timer? _focusTimer;

  @override
  void dispose() {
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
    final hints = _suggestions(s);
    final mq = MediaQuery.of(context);

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

          // Subtle vignette
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                  ),
                ),
              ),
            ),
          ),

          // Optional rule-of-thirds grid
          if (s.isGridOverlayOn)
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GridPainter()))),

          // Centered document guide with corner brackets
          Positioned.fill(
            child: LayoutBuilder(builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final guideW = w * 0.86;
              final guideH = (h * 0.50).clamp(260.0, 460.0);
              final left = (w - guideW) / 2;
              final top = (h - guideH) / 2 - 16;
              return IgnorePointer(
                child: Stack(
                  children: [
                    // Dim everything except the rounded document frame
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _FrameDimPainter(
                          frame: Rect.fromLTWH(left, top, guideW, guideH),
                          radius: 18,
                        ),
                      ),
                    ),
                    // Corner brackets
                    Positioned(
                      left: left,
                      top: top,
                      child: CustomPaint(
                        size: Size(guideW, guideH),
                        painter: const _CornerBracketsPainter(),
                      ),
                    ),
                  ],
                ),
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
              top: mq.size.height * 0.47,
              left: mq.size.width * 0.30,
              right: mq.size.width * 0.30,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: AppColors.neonGreen, blurRadius: 8)],
                ),
              ),
            ),

          // ── Top bar ──────────────────────────────────────────────────────
          Positioned(
            top: mq.padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassBtn(icon: Icons.arrow_back_rounded, onTap: () => context.pop()),
                const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.42),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded,
                              color: AppColors.neonPurple, size: 14),
                          const SizedBox(width: 6),
                          const Text('AI Camera',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _GlassBtn(
                  icon: _flashIcon(s.flashMode),
                  active: s.flashMode != 'off',
                  onTap: () => ctrl.cycleFlashMode(),
                ),
                const SizedBox(width: 8),
                _GlassBtn(
                  icon: Icons.cameraswitch_rounded,
                  onTap: () => ctrl.switchCamera(),
                ),
                const SizedBox(width: 8),
                _GlassBtn(icon: Icons.tune_rounded, onTap: _openSettings),
              ],
            ),
          ),

          // ── Scan mode chips ──────────────────────────────────────────────
          Positioned(
            top: mq.padding.top + 60,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 38,
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
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      decoration: BoxDecoration(
                        gradient: selected ? AppColors.scannerGradient : null,
                        color: selected ? null : Colors.black.withOpacity(0.42),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? Colors.white.withOpacity(0.25)
                              : Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(meta.icon, color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text(meta.label,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Quality / stability badge (compact, above bottom controls) ──
          Positioned(
            left: 0,
            right: 0,
            bottom: mq.padding.bottom + 168,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: s.isBlurDetected
                      ? AppColors.error.withOpacity(0.92)
                      : Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: s.isBlurDetected
                        ? Colors.redAccent
                        : AppColors.neonGreen.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      s.isBlurDetected
                          ? Icons.warning_amber_rounded
                          : Icons.verified_rounded,
                      color: s.isBlurDetected ? Colors.white : AppColors.neonGreen,
                      size: 13,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.qualityFeedback,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hint pills ──────────────────────────────────────────────────
          if (hints.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: mq.padding.bottom + 132,
              child: SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: hints.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.neonPurple.withOpacity(0.35)),
                    ),
                    child: Text(hints[i],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),

          // ── Bottom control panel ────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 10, 16, mq.padding.bottom + 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick tools row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _QuickTool(
                          icon: Icons.auto_fix_high_rounded,
                          label: 'Filters',
                          active: s.filterMode != ColorFilterMode.original &&
                              s.filterMode != ColorFilterMode.autoEnhanced,
                          onTap: _openFilters,
                        ),
                        _QuickTool(
                          icon: Icons.grid_on_rounded,
                          label: 'Grid',
                          active: s.isGridOverlayOn,
                          onTap: () => ctrl.toggleGridOverlay(),
                        ),
                        _QuickTool(
                          icon: s.timerSeconds > 0
                              ? Icons.timer_rounded
                              : Icons.timer_off_rounded,
                          label: s.timerSeconds > 0 ? '${s.timerSeconds}s' : 'Timer',
                          active: s.timerSeconds > 0,
                          onTap: () => ctrl.cycleTimer(),
                        ),
                        _QuickTool(
                          icon: Icons.auto_awesome,
                          label: 'AI Enh.',
                          active: s.filterMode == ColorFilterMode.aiEnhance,
                          onTap: () => ctrl.setColorFilter(ColorFilterMode.aiEnhance),
                        ),
                        _QuickTool(
                          icon: Icons.invert_colors_rounded,
                          label: 'B&W',
                          active: s.filterMode == ColorFilterMode.blackAndWhite,
                          onTap: () =>
                              ctrl.setColorFilter(ColorFilterMode.blackAndWhite),
                        ),
                        _QuickTool(
                          icon: Icons.nightlight_round,
                          label: 'Night',
                          active: s.flashMode == 'torch',
                          onTap: () => ctrl.enableNightMode(),
                        ),
                        _QuickTool(
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI Chat',
                          active: s.isAiAssistOn,
                          onTap: () {
                            ctrl.toggleAiAssist();
                            context.push(RouteNames.aiAssistant);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Main capture row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.18),
                                border:
                                    Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.scannerGradient,
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.primaryDark.withOpacity(0.5),
                                      blurRadius: 14),
                                ],
                              ),
                              child: s.isCapturing
                                  ? const Center(
                                      child: SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.6,
                                              color: Colors.white)))
                                  : const Icon(Icons.camera_alt_rounded,
                                      color: Colors.white, size: 28),
                            ),
                            if (s.timerSeconds > 0)
                              Container(
                                width: 78,
                                height: 78,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle, color: Colors.black54),
                                child: Center(
                                  child: Text('${s.timerSeconds}s',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20)),
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
                ],
              ),
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
// Reusable buttons
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: active ? AppColors.scannerGradient : null,
          color: active ? null : Colors.black.withOpacity(0.42),
          shape: BoxShape.circle,
          border: Border.all(
              color: active ? Colors.white.withOpacity(0.22) : Colors.white.withOpacity(0.16)),
          boxShadow: active
              ? [BoxShadow(color: AppColors.primaryDark.withOpacity(0.35), blurRadius: 12)]
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _QuickTool extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  const _QuickTool(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.active = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: active ? AppColors.scannerGradient : null,
            color: active ? null : Colors.black.withOpacity(0.42),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: active ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
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
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
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
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600))),
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
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primaryDark.withOpacity(0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: const Icon(Icons.document_scanner_rounded,
                    color: Colors.white, size: 42),
              ),
              const SizedBox(height: 18),
              const Text('Premium AI Camera Ready',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('AI edge detection • Auto capture • HD',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onImport,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Import from Gallery',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
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

// Paints a semi-transparent overlay with a transparent rounded "hole" for
// the document guide frame.
class _FrameDimPainter extends CustomPainter {
  final Rect frame;
  final double radius;
  _FrameDimPainter({required this.frame, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.45);
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(frame, Radius.circular(radius)));
    final combined = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(covariant _FrameDimPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.radius != radius;
}

// Paints the rule-of-thirds grid.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..strokeWidth = 0.8;
    canvas.drawLine(
        Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(size.width * 2 / 3, 0),
        Offset(size.width * 2 / 3, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, size.height * 2 / 3),
        Offset(size.width, size.height * 2 / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Paints four L-shaped corner brackets around the document guide frame.
class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonCyan.withOpacity(0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 26.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(18),
    );

    // Top-left
    canvas.drawLine(r.outerRect.topLeft.translate(0, len),
        r.outerRect.topLeft, paint);
    canvas.drawLine(r.outerRect.topLeft,
        r.outerRect.topLeft.translate(len, 0), paint);
    // Top-right
    canvas.drawLine(r.outerRect.topRight.translate(0, len),
        r.outerRect.topRight, paint);
    canvas.drawLine(r.outerRect.topRight,
        r.outerRect.topRight.translate(-len, 0), paint);
    // Bottom-left
    canvas.drawLine(r.outerRect.bottomLeft.translate(0, -len),
        r.outerRect.bottomLeft, paint);
    canvas.drawLine(r.outerRect.bottomLeft,
        r.outerRect.bottomLeft.translate(len, 0), paint);
    // Bottom-right
    canvas.drawLine(r.outerRect.bottomRight.translate(0, -len),
        r.outerRect.bottomRight, paint);
    canvas.drawLine(r.outerRect.bottomRight,
        r.outerRect.bottomRight.translate(-len, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
