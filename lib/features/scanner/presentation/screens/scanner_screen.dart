import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/injection/injection_container.dart';
import '../../../../config/routes/route_names.dart';
import '../../../../domain/repositories/document_repository.dart';
import '../../../../models/document_item.dart';
import '../controllers/scanner_controller.dart';

class _ScanModeMeta {
  final ScanMode mode;
  final String label;
  final IconData icon;

  const _ScanModeMeta(this.mode, this.label, this.icon);
}

class _FilterMeta {
  final String label;
  final ColorFilterMode mode;
  final IconData icon;

  const _FilterMeta(this.label, this.mode, this.icon);
}

const List<_ScanModeMeta> _camScannerModes = [
  _ScanModeMeta(ScanMode.idCard, 'ID Card', Icons.badge_outlined),
  _ScanModeMeta(ScanMode.document, 'Single', Icons.crop_portrait_rounded),
  _ScanModeMeta(ScanMode.batch, 'Batch', Icons.dynamic_feed_outlined),
  _ScanModeMeta(ScanMode.book, 'Book', Icons.menu_book_outlined),
  _ScanModeMeta(ScanMode.homework, 'Question Book', Icons.school_outlined),
];

const List<_FilterMeta> _camScannerFilters = [
  _FilterMeta('No Shadow', ColorFilterMode.autoEnhanced, Icons.wb_sunny_outlined),
  _FilterMeta('Original', ColorFilterMode.original, Icons.image_outlined),
  _FilterMeta('Lighten', ColorFilterMode.highContrast, Icons.light_mode_outlined),
  _FilterMeta('Magic Color', ColorFilterMode.color, Icons.auto_fix_high_outlined),
  _FilterMeta('B&W', ColorFilterMode.blackAndWhite, Icons.contrast_outlined),
  _FilterMeta('Gray', ColorFilterMode.grayscale, Icons.tonality_outlined),
];

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _cornerController;
  late final AnimationController _scanController;
  late final AnimationController _capturePulseController;
  Offset? _focusPoint;
  bool _focusVisible = false;
  String _selectedFilterLabel = 'No Shadow';
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    _cornerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _capturePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _cornerController.dispose();
    _scanController.dispose();
    _capturePulseController.dispose();
    super.dispose();
  }

  ColorFilter? _liveFilter(ColorFilterMode mode) {
    switch (mode) {
      case ColorFilterMode.blackAndWhite:
      case ColorFilterMode.grayscale:
      case ColorFilterMode.signature:
        return const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ColorFilterMode.color:
      case ColorFilterMode.autoEnhanced:
      case ColorFilterMode.aiEnhance:
      case ColorFilterMode.magazine:
      case ColorFilterMode.book:
      case ColorFilterMode.receipt:
        return const ColorFilter.matrix(<double>[
          1.10,
          0,
          0,
          0,
          4,
          0,
          1.10,
          0,
          0,
          4,
          0,
          0,
          1.18,
          0,
          5,
          0,
          0,
          0,
          1,
          0,
        ]);
      case ColorFilterMode.highContrast:
        return const ColorFilter.matrix(<double>[
          1.24,
          0,
          0,
          0,
          12,
          0,
          1.24,
          0,
          0,
          12,
          0,
          0,
          1.24,
          0,
          12,
          0,
          0,
          0,
          1,
          0,
        ]);
      default:
        return null;
    }
  }

  void _applyMode(ScanMode mode) {
    final ctrl = ref.read(scannerProvider.notifier);
    ctrl.setScanMode(mode);
    switch (mode) {
      case ScanMode.idCard:
        ctrl.setColorFilter(ColorFilterMode.passport);
        setState(() => _selectedFilterLabel = 'Original');
        break;
      case ScanMode.book:
      case ScanMode.homework:
        ctrl.setColorFilter(ColorFilterMode.book);
        setState(() => _selectedFilterLabel = 'Magic Color');
        break;
      case ScanMode.batch:
      case ScanMode.document:
      default:
        ctrl.setColorFilter(ColorFilterMode.autoEnhanced);
        setState(() => _selectedFilterLabel = 'No Shadow');
        break;
    }
  }

  void _showFocusRing(Offset normalized) {
    setState(() {
      _focusPoint = normalized;
      _focusVisible = true;
    });
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _focusVisible = false);
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onCapture() async {
    final state = ref.read(scannerProvider);
    final ctrl = ref.read(scannerProvider.notifier);

    if (state.currentMode == ScanMode.qr) {
      if (context.mounted) context.push(RouteNames.qrScanner);
      return;
    }

    // HDR + deblur is now handled inside capturePhoto().
    final path = await ctrl.capturePhoto();
    if (path == null || !context.mounted) return;

    String finalPath = path;

    // Apply additional colour / shadow filter on top of HDR (if not already HDR)
    final shouldFilter = !state.isHdrOn &&
        (state.isShadowRemovalEnabled ||
            state.filterMode != ColorFilterMode.original);
    if (shouldFilter) {
      final enhanced = await ctrl.applyFilterToFile(path, state.filterMode);
      if (enhanced != null && context.mounted) {
        finalPath = enhanced;
        ctrl.replaceLastCapturedImage(finalPath);
      }
    }

    if (!context.mounted) return;
    if (state.currentMode == ScanMode.batch) {
      final postState = ref.read(scannerProvider);
      String msg = 'Page ${postState.capturedImages.length} captured.';
      if (postState.isHdrOn) msg += ' HDR ✓';
      if (postState.isAutoDeblurOn && postState.isBlurDetected) msg += ' Deblur ✓';
      msg += ' Tap preview to export.';
      _showSnack(msg);
      return;
    }
    context.push(RouteNames.crop, extra: finalPath);
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
      _showSnack('Import failed: $e');
    }
  }

  Future<void> _openBatchPreview() async {
    final images = ref.read(scannerProvider).capturedImages;
    if (images.isEmpty) {
      _showSnack('Capture or import pages first.');
      return;
    }
    context.push(RouteNames.scanPreview, extra: images);
  }

  Future<void> _shareCurrentScans() async {
    final images = ref.read(scannerProvider).capturedImages;
    if (images.isEmpty) {
      _showSnack('Capture or import pages first.');
      return;
    }
    await Share.shareXFiles(
      images.map((path) => XFile(path)).toList(),
      text: 'Scanned with ScanX AI',
    );
  }

  void _showTemplatesSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CamSheet(
        title: 'Document Templates',
        children: [
          _SheetAction(
            icon: Icons.badge_outlined,
            title: 'ID Card front/back',
            subtitle: 'Guided two-sided ID scan template',
            onTap: () {
              Navigator.pop(context);
              _applyMode(ScanMode.idCard);
            },
          ),
          _SheetAction(
            icon: Icons.receipt_long_outlined,
            title: 'Receipt / Invoice',
            subtitle: 'High-contrast expense document enhancement',
            onTap: () {
              Navigator.pop(context);
              ref.read(scannerProvider.notifier)
                ..setScanMode(ScanMode.receipt)
                ..setColorFilter(ColorFilterMode.receipt);
              setState(() => _selectedFilterLabel = 'Lighten');
            },
          ),
          _SheetAction(
            icon: Icons.menu_book_outlined,
            title: 'Book split pages',
            subtitle: 'Book mode with shadow-removal filter',
            onTap: () {
              Navigator.pop(context);
              _applyMode(ScanMode.book);
            },
          ),
          _SheetAction(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Import PDF',
            subtitle: 'Add an existing PDF to scan history',
            onTap: () {
              Navigator.pop(context);
              _importPdf();
            },
          ),
        ],
      ),
    );
  }

  void _showMoreMenu() {
    final ctrl = ref.read(scannerProvider.notifier);
    final s = ref.read(scannerProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CamSheet(
        title: 'Scanner Tools',
        children: [
          _SheetSwitch(
            icon: Icons.auto_awesome_outlined,
            title: 'Auto edge detection / Auto scan',
            value: s.isAutoCaptureEnabled,
            onChanged: (_) {
              ctrl.toggleAutoCapture();
              Navigator.pop(context);
            },
          ),
          _SheetSwitch(
            icon: Icons.hdr_on_rounded,
            title: 'HDR tone mapping',
            value: s.isHdrOn,
            onChanged: (_) {
              ctrl.toggleHdr();
              Navigator.pop(context);
            },
          ),
          _SheetSwitch(
            icon: Icons.wb_sunny_outlined,
            title: 'Shadow removal',
            value: s.isShadowRemovalEnabled,
            onChanged: (_) {
              ctrl.toggleShadowRemoval();
              Navigator.pop(context);
            },
          ),
          _SheetAction(
            icon: Icons.document_scanner_outlined,
            title: 'Crop editor / Perspective correction',
            subtitle: 'Capture opens the crop editor with edge handles',
            onTap: () {
              Navigator.pop(context);
              _showSnack('Capture a page to open the crop editor.');
            },
          ),
          _SheetAction(
            icon: Icons.text_snippet_outlined,
            title: 'OCR',
            subtitle: 'Open extracted text and document viewer',
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.ocrViewer);
            },
          ),
          _SheetAction(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Export PDF / JPG',
            subtitle: 'Reorder pages, generate PDF, and share',
            onTap: () {
              Navigator.pop(context);
              _openBatchPreview();
            },
          ),
          _SheetAction(
            icon: Icons.ios_share_outlined,
            title: 'Share',
            subtitle: 'Share captured pages with other apps',
            onTap: () {
              Navigator.pop(context);
              _shareCurrentScans();
            },
          ),
          _SheetAction(
            icon: Icons.history_outlined,
            title: 'Scan history',
            subtitle: 'Open saved documents',
            onTap: () {
              Navigator.pop(context);
              context.go(RouteNames.home);
            },
          ),
          _SheetAction(
            icon: Icons.cloud_sync_outlined,
            title: 'Cloud sync support',
            subtitle: 'Back up scans to cloud storage',
            onTap: () {
              Navigator.pop(context);
              context.push(RouteNames.cloudSync);
            },
          ),
          _SheetAction(
            icon: Icons.settings_outlined,
            title: 'Advanced camera settings',
            subtitle: 'Grid, level, timer, exposure lock, night mode',
            onTap: () {
              Navigator.pop(context);
              _showAdvancedSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showAdvancedSettings() {
    final ctrl = ref.read(scannerProvider.notifier);
    final s = ref.read(scannerProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _CamSheet(
        title: 'Camera Settings',
        children: [
          _SheetSwitch(
            icon: Icons.grid_on_outlined,
            title: 'Composition grid',
            value: s.isGridOverlayOn,
            onChanged: (_) {
              ctrl.toggleGridOverlay();
              Navigator.pop(context);
            },
          ),
          _SheetSwitch(
            icon: Icons.straighten_outlined,
            title: 'Level indicator',
            value: s.isLevelIndicatorOn,
            onChanged: (_) {
              ctrl.toggleLevelIndicator();
              Navigator.pop(context);
            },
          ),
          _SheetSwitch(
            icon: Icons.lock_outline,
            title: 'Lock exposure',
            value: s.isExposureLocked,
            onChanged: (_) {
              ctrl.toggleExposureLock();
              Navigator.pop(context);
            },
          ),
          _SheetAction(
            icon: Icons.timer_outlined,
            title: 'Timer: ${s.timerSeconds == 0 ? 'Off' : '${s.timerSeconds}s'}',
            subtitle: 'Cycle 3s, 5s, 10s capture delay',
            onTap: () {
              ctrl.cycleTimer();
              Navigator.pop(context);
            },
          ),
          _SheetSwitch(
            icon: Icons.blur_off_rounded,
            title: 'Auto blur correction',
            value: s.isAutoDeblurOn,
            onChanged: (_) {
              ctrl.toggleAutoDeblur();
              Navigator.pop(context);
            },
          ),
          _SheetAction(
            icon: Icons.nightlight_outlined,
            title: 'Night / torch mode',
            subtitle: 'Continuous light for low-light scans',
            onTap: () {
              ctrl.enableNightMode();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Rect _documentRect(Size size) {
    final width = (size.width * 0.86).clamp(300.0, 620.0).toDouble();
    final maxHeight = math.max(320.0, size.height * 0.54);
    final height = (width * 1.28).clamp(300.0, maxHeight).toDouble();
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.43),
      width: width,
      height: height,
    );
  }

  List<Offset> _detectedCorners(Rect r) => [
        Offset(r.left + r.width * .045, r.top + r.height * .055),
        Offset(r.right - r.width * .040, r.top + r.height * .025),
        Offset(r.right - r.width * .030, r.bottom - r.height * .060),
        Offset(r.left + r.width * .055, r.bottom - r.height * .025),
      ];

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(scannerProvider);
    final ctrl = ref.read(scannerProvider.notifier);
    final filter = _liveFilter(s.filterMode);
    final mq = MediaQuery.of(context);
    final bottomSafe = mq.padding.bottom;

    final preview = s.isInitialized && ctrl.cameraController != null
        ? LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final p = Offset(
                  (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble(),
                  (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0).toDouble(),
                );
                ctrl.setFocusPoint(p);
                _showFocusRing(p);
              },
              onScaleUpdate: (details) {
                if (details.scale == 1) return;
                final next = s.zoomLevel * details.scale;
                ctrl.setZoomLevel(next);
              },
              child: filter == null
                  ? _CameraPreviewCover(controller: ctrl.cameraController!)
                  : ColorFiltered(
                      colorFilter: filter,
                      child: _CameraPreviewCover(controller: ctrl.cameraController!),
                    ),
            ),
          )
        : _FallbackPreview(onImport: _importGallery);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: preview),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.62),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(.82),
                  ],
                  stops: const [0, .20, .58, 1],
                ),
              ),
            ),
          ),
          if (s.isGridOverlayOn)
            const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _GridPainter()))),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_cornerController, _scanController]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _DocumentDetectionPainter(
                    documentRect: _documentRect(mq.size),
                    corners: _detectedCorners(_documentRect(mq.size)),
                    cornerT: _cornerController.value,
                    scanT: _scanController.value,
                    autoScan: s.isAutoCaptureEnabled,
                    showLevel: s.isLevelIndicatorOn,
                  ),
                );
              },
            ),
          ),
          // Status indicators (blur/HDR/deblur)
          Positioned(
            left: 0,
            right: 0,
            top: mq.size.height * .42,
            child: IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusPill(
                      icon: s.isBlurDetected
                          ? Icons.blur_on_rounded
                          : (s.isHdrOn ? Icons.hdr_on_rounded : Icons.check_circle_outline),
                      label: s.isBlurDetected
                          ? 'Blur detected • Hold steady'
                          : (s.isHdrOn
                              ? 'HDR tone mapping active'
                              : 'Document detected • Auto crop ready'),
                      danger: s.isBlurDetected,
                      hdrActive: s.isHdrOn && !s.isBlurDetected,
                    ),
                    if (s.isBlurDetected && s.isAutoDeblurOn) ...[
                      const SizedBox(height: 6),
                      _DeblurBadge(qualityScore: s.aiQualityScore),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: mq.size.height * .50,
            child: IgnorePointer(
              child: _PerspectiveMiniPreview(active: s.isAutoCaptureEnabled),
            ),
          ),
          if (_focusVisible && _focusPoint != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final x = _focusPoint!.dx * constraints.maxWidth;
                  final y = _focusPoint!.dy * constraints.maxHeight;
                  return Stack(
                    children: [
                      Positioned(
                        left: x - 31,
                        top: y - 31,
                        child: const _FocusRing(),
                      ),
                    ],
                  );
                },
              ),
            ),
          Positioned(
            top: mq.padding.top + 8,
            left: 10,
            right: 10,
            child: _TopBar(
              flashMode: s.flashMode,
              hdOn: s.isHdrOn,
              autoOn: s.isAutoCaptureEnabled,
              canSwitchCamera: s.canSwitchCamera,
              onBack: () => context.pop(),
              onFlash: ctrl.cycleFlashMode,
              onHd: ctrl.toggleHdr,
              onAuto: ctrl.toggleAutoCapture,
              onSwitchCamera: ctrl.switchCamera,
              onMore: _showMoreMenu,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomSafe + 145,
            child: _FilterBar(
              selected: _selectedFilterLabel,
              onSelected: (filter) {
                ref.read(scannerProvider.notifier).setColorFilter(filter.mode);
                if (filter.label == 'No Shadow' && !s.isShadowRemovalEnabled) {
                  ref.read(scannerProvider.notifier).toggleShadowRemoval();
                }
                setState(() => _selectedFilterLabel = filter.label);
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomSafe + 97,
            child: _ModeBar(
              currentMode: s.currentMode,
              onSelected: _applyMode,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(
              bottomPadding: bottomSafe,
              isCapturing: s.isCapturing,
              pageCount: s.capturedImages.length,
              pulse: _capturePulseController,
              onImport: _importGallery,
              onQr: () => context.push(RouteNames.qrScanner),
              onCapture: s.isCapturing ? null : _onCapture,
              onTemplates: _showTemplatesSheet,
              onMore: _showMoreMenu,
              onPreviewPages: _openBatchPreview,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewCover extends StatelessWidget {
  final CameraController controller;

  const _CameraPreviewCover({required this.controller});

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    if (!value.isInitialized) return const SizedBox.expand();

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = value.previewSize ?? Size(constraints.maxWidth, constraints.maxHeight);
        final previewAspect = previewSize.height / previewSize.width;
        final screenAspect = constraints.maxWidth / constraints.maxHeight;
        return ClipRect(
          child: Transform.scale(
            scale: previewAspect / screenAspect,
            child: Center(child: CameraPreview(controller)),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final String flashMode;
  final bool hdOn;
  final bool autoOn;
  final bool canSwitchCamera;
  final VoidCallback onBack;
  final VoidCallback onFlash;
  final VoidCallback onHd;
  final VoidCallback onAuto;
  final VoidCallback onSwitchCamera;
  final VoidCallback onMore;

  const _TopBar({
    required this.flashMode,
    required this.hdOn,
    required this.autoOn,
    required this.canSwitchCamera,
    required this.onBack,
    required this.onFlash,
    required this.onHd,
    required this.onAuto,
    required this.onSwitchCamera,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopIcon(icon: Icons.close_rounded, onTap: onBack),
        const Spacer(),
        _TopIcon(
          icon: _flashIcon(flashMode),
          label: flashMode.toUpperCase(),
          onTap: onFlash,
          active: flashMode != 'off',
        ),
        _TopIcon(
          icon: Icons.hdr_on_rounded,
          label: 'HDR',
          onTap: onHd,
          active: hdOn,
          activeColor: hdOn ? const Color(0xFF6EC6FF) : null,
        ),
        _TopIcon(
          icon: Icons.auto_awesome_rounded,
          label: 'AUTO',
          onTap: onAuto,
          active: autoOn,
        ),
        _TopIcon(
          icon: Icons.cameraswitch_outlined,
          onTap: canSwitchCamera ? onSwitchCamera : () {},
          active: canSwitchCamera,
        ),
        _TopIcon(icon: Icons.more_vert_rounded, onTap: onMore),
      ],
    );
  }

  IconData _flashIcon(String mode) {
    switch (mode) {
      case 'auto':
        return Icons.flash_auto_rounded;
      case 'on':
        return Icons.flash_on_rounded;
      case 'torch':
        return Icons.highlight_rounded;
      default:
        return Icons.flash_off_rounded;
    }
  }
}

class _TopIcon extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  const _TopIcon({
    required this.icon,
    required this.onTap,
    this.label,
    this.active = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? (activeColor ?? const Color(0xFF21E56E)) : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          constraints: const BoxConstraints(minWidth: 40),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.28),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(.09)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    label!,
                    style: TextStyle(
                      color: color,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<_FilterMeta> onSelected;

  const _FilterBar({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = _camScannerFilters[index];
          final isSelected = filter.label == selected;
          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.black.withOpacity(.42),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(.16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: 16,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter.label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _camScannerFilters.length,
      ),
    );
  }
}

class _ModeBar extends StatelessWidget {
  final ScanMode currentMode;
  final ValueChanged<ScanMode> onSelected;

  const _ModeBar({required this.currentMode, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final meta = _camScannerModes[index];
          final selected = meta.mode == currentMode ||
              (meta.mode == ScanMode.document && currentMode == ScanMode.receipt);
          return GestureDetector(
            onTap: () => onSelected(meta.mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meta.label,
                  style: TextStyle(
                    color: selected ? const Color(0xFFFFD94A) : Colors.white.withOpacity(.76),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 24 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD94A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemCount: _camScannerModes.length,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final double bottomPadding;
  final bool isCapturing;
  final int pageCount;
  final Animation<double> pulse;
  final VoidCallback onImport;
  final VoidCallback onQr;
  final VoidCallback? onCapture;
  final VoidCallback onTemplates;
  final VoidCallback onMore;
  final VoidCallback onPreviewPages;

  const _BottomNav({
    required this.bottomPadding,
    required this.isCapturing,
    required this.pageCount,
    required this.pulse,
    required this.onImport,
    required this.onQr,
    required this.onCapture,
    required this.onTemplates,
    required this.onMore,
    required this.onPreviewPages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, math.max(10.0, bottomPadding + 4)),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.72),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _NavButton(icon: Icons.photo_library_outlined, label: 'Import', onTap: onImport),
          _NavButton(icon: Icons.qr_code_scanner_rounded, label: 'QR Code', onTap: onQr),
          GestureDetector(
            onTap: onCapture,
            onLongPress: onPreviewPages,
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 84 + (pulse.value * 4),
                      height: 84 + (pulse.value * 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(.10),
                        border: Border.all(color: Colors.white, width: 3.2),
                      ),
                    ),
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.document_scanner_rounded, color: Colors.black, size: 30),
                    ),
                    if (pageCount > 0)
                      Positioned(
                        right: -2,
                        top: -4,
                        child: GestureDetector(
                          onTap: onPreviewPages,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD94A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 1.2),
                            ),
                            child: Text(
                              '$pageCount',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _NavButton(icon: Icons.dashboard_customize_outlined, label: 'Templates', onTap: onTemplates),
          _NavButton(icon: Icons.more_horiz_rounded, label: 'More', onTap: onMore),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 25),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  final bool hdrActive;

  const _StatusPill({
    required this.icon,
    required this.label,
    this.danger = false,
    this.hdrActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? const Color(0xFFFF6060)
        : (hdrActive ? const Color(0xFF6EC6FF) : const Color(0xFF21E56E));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.65)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(.22), blurRadius: hdrActive ? 24 : 16),
          if (hdrActive)
            BoxShadow(
              color: const Color(0xFF6EC6FF).withOpacity(.12),
              blurRadius: 40,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: hdrActive ? const Color(0xFF6EC6FF) : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeblurBadge extends StatelessWidget {
  final int qualityScore;
  const _DeblurBadge({required this.qualityScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.50),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD94A).withOpacity(.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFFFD94A), size: 13),
          const SizedBox(width: 5),
          Text(
            'Auto-deblur active • Quality: $qualityScore/100',
            style: const TextStyle(
              color: Color(0xFFFFD94A),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerspectiveMiniPreview extends StatelessWidget {
  final bool active;

  const _PerspectiveMiniPreview({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 240),
      opacity: active ? 1 : .58,
      child: Column(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .001)
              ..rotateZ(-.025),
            child: Container(
              width: 64,
              height: 84,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF21E56E), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  6,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Container(
                      width: i == 0 ? 36.0 : (42 - (i % 2) * 10).toDouble(),
                      height: i == 0 ? 7 : 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(i == 0 ? .65 : .22),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Corrected',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _FocusRing extends StatelessWidget {
  const _FocusRing();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.25, end: 1),
      duration: const Duration(milliseconds: 180),
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFFD94A), width: 2),
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Color(0xFFFFD94A), shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _CamSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _CamSheet({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .76),
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(.08)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(.08),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(.62), fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
    );
  }
}

class _SheetSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SheetSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(.08),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      value: value,
      activeColor: const Color(0xFF21E56E),
      onChanged: onChanged,
    );
  }
}

class _FallbackPreview extends StatelessWidget {
  final VoidCallback onImport;

  const _FallbackPreview({required this.onImport});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF101010),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _FallbackTexturePainter()),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 54),
                  const SizedBox(height: 14),
                  const Text(
                    'Camera preview unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Import images from gallery and continue with auto crop, enhancement, OCR, PDF export, and sharing.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(.68), height: 1.35),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: onImport,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Import from gallery'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentDetectionPainter extends CustomPainter {
  final Rect documentRect;
  final List<Offset> corners;
  final double cornerT;
  final double scanT;
  final bool autoScan;
  final bool showLevel;

  _DocumentDetectionPainter({
    required this.documentRect,
    required this.corners,
    required this.cornerT,
    required this.scanT,
    required this.autoScan,
    required this.showLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;
    final polygon = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addPath(polygon, Offset.zero)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlay, Paint()..color = Colors.black.withOpacity(.46));

    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(.22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(documentRect, const Radius.circular(18)),
      guidePaint,
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF21E56E).withOpacity(.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(polygon, glowPaint);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF21E56E);
    canvas.drawPath(polygon, edgePaint);

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = Colors.white.withOpacity(.72);
    canvas.drawPath(polygon, innerPaint);

    final scanY = documentRect.top + documentRect.height * scanT;
    final scanPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xFF21E56E), Colors.transparent],
      ).createShader(Rect.fromLTWH(documentRect.left, scanY - 1, documentRect.width, 2))
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawLine(Offset(documentRect.left + 16, scanY), Offset(documentRect.right - 16, scanY), scanPaint);

    final pulse = 1 + cornerT * .20;
    final cornerLength = 34 + cornerT * 8;
    final cornerStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFD94A);
    _drawGuideCorner(canvas, documentRect.topLeft, 1, 1, cornerLength * pulse, cornerStroke);
    _drawGuideCorner(canvas, documentRect.topRight, -1, 1, cornerLength * pulse, cornerStroke);
    _drawGuideCorner(canvas, documentRect.bottomRight, -1, -1, cornerLength * pulse, cornerStroke);
    _drawGuideCorner(canvas, documentRect.bottomLeft, 1, -1, cornerLength * pulse, cornerStroke);

    if (showLevel) {
      final levelPaint = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF21E56E).withOpacity(.86);
      final cx = size.width / 2;
      final cy = documentRect.center.dy;
      canvas.drawLine(Offset(cx - 46, cy), Offset(cx + 46, cy), levelPaint);
      canvas.drawCircle(Offset(cx, cy), 3.5, Paint()..color = const Color(0xFF21E56E));
    }

    final labelPainter = TextPainter(
      text: TextSpan(
        text: autoScan ? 'AUTO SCAN' : 'MANUAL',
        style: TextStyle(
          color: autoScan ? const Color(0xFF21E56E) : Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelOffset = Offset(
      documentRect.center.dx - labelPainter.width / 2,
      documentRect.bottom + 18,
    );
    final bg = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelOffset.dx - 10, labelOffset.dy - 6, labelPainter.width + 20, labelPainter.height + 12),
      const Radius.circular(14),
    );
    canvas.drawRRect(bg, Paint()..color = Colors.black.withOpacity(.42));
    labelPainter.paint(canvas, labelOffset);
  }

  void _drawGuideCorner(Canvas canvas, Offset anchor, int sx, int sy, double len, Paint paint) {
    canvas.drawLine(anchor, anchor + Offset(sx * len, 0), paint);
    canvas.drawLine(anchor, anchor + Offset(0, sy * len), paint);
  }

  @override
  bool shouldRepaint(covariant _DocumentDetectionPainter oldDelegate) {
    return documentRect != oldDelegate.documentRect ||
        corners != oldDelegate.corners ||
        cornerT != oldDelegate.cornerT ||
        scanT != oldDelegate.scanT ||
        autoScan != oldDelegate.autoScan ||
        showLevel != oldDelegate.showLevel;
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.16)
      ..strokeWidth = .7;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(Offset(size.width * i / 3, 0), Offset(size.width * i / 3, size.height), paint);
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FallbackTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF171717), Color(0xFF0B0B0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(.035)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + size.width * .22), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
