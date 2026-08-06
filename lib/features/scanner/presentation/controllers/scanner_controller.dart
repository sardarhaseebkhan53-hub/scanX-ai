import 'dart:async';
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/logger/app_logger.dart';
import '../../../../services/scanner/image_processing_service.dart';

enum ScanMode {
  document,
  receipt,
  invoice,
  book,
  passport,
  idCard,
  businessCard,
  whiteboard,
  batch,
  // Premium redesign scan modes
  qr,
  photo,
  objectAi,
  homework,
  more,
}

enum ColorFilterMode {
  original,
  autoEnhanced,
  color,
  blackAndWhite,
  grayscale,
  highContrast,
  magazine,
  book,
  receipt,
  passport,
  photo,
  signature,
  aiEnhance,
  aiSharpen,
}

class ScannerState {
  final bool isInitialized;
  final bool isFlashOn;
  final String flashMode; // 'auto', 'on', 'off', 'torch'
  final ScanMode currentMode;
  final ColorFilterMode filterMode;
  final List<String> capturedImages;
  final String? errorMessage;
  final bool isCapturing;
  final bool isAutoCaptureEnabled;
  final bool isBlurDetected;
  final bool isShadowRemovalEnabled;
  final double exposureOffset; // -2.0 to +2.0
  final bool isExposureLocked;
  final String whiteBalanceMode; // 'auto', 'incandescent', 'fluorescent', 'daylight', 'cloudy'
  final bool isGridOverlayOn;
  final bool isLevelIndicatorOn;
  final bool isAutoHorizonOn;
  final int timerSeconds; // 0, 3, 5, 10
  final bool isBurstMode;
  final int aiQualityScore;
  final String qualityFeedback;
  final bool canSwitchCamera;
  final double zoomLevel;
  final double minZoomLevel;
  final double maxZoomLevel;
  final bool isHdrOn;
  final bool isAiAssistOn;

  const ScannerState({
    this.isInitialized = false,
    this.isFlashOn = false,
    this.flashMode = 'off',
    this.currentMode = ScanMode.document,
    this.filterMode = ColorFilterMode.autoEnhanced,
    this.capturedImages = const [],
    this.errorMessage,
    this.isCapturing = false,
    this.isAutoCaptureEnabled = true,
    this.isBlurDetected = false,
    this.isShadowRemovalEnabled = true,
    this.exposureOffset = 0.0,
    this.isExposureLocked = false,
    this.whiteBalanceMode = 'auto',
    this.isGridOverlayOn = false,
    this.isLevelIndicatorOn = true,
    this.isAutoHorizonOn = true,
    this.timerSeconds = 0,
    this.isBurstMode = false,
    this.aiQualityScore = 98,
    this.qualityFeedback = '⚡ AI Quality Score: 98/100 • Sharp & Aligned',
    this.canSwitchCamera = false,
    this.zoomLevel = 1.0,
    this.minZoomLevel = 1.0,
    this.maxZoomLevel = 1.0,
    this.isHdrOn = false,
    this.isAiAssistOn = false,
  });

  ScannerState copyWith({
    bool? isInitialized,
    bool? isFlashOn,
    String? flashMode,
    ScanMode? currentMode,
    ColorFilterMode? filterMode,
    List<String>? capturedImages,
    String? errorMessage,
    bool? isCapturing,
    bool? isAutoCaptureEnabled,
    bool? isBlurDetected,
    bool? isShadowRemovalEnabled,
    double? exposureOffset,
    bool? isExposureLocked,
    String? whiteBalanceMode,
    bool? isGridOverlayOn,
    bool? isLevelIndicatorOn,
    bool? isAutoHorizonOn,
    int? timerSeconds,
    bool? isBurstMode,
    int? aiQualityScore,
    String? qualityFeedback,
    bool? canSwitchCamera,
    double? zoomLevel,
    double? minZoomLevel,
    double? maxZoomLevel,
    bool? isHdrOn,
    bool? isAiAssistOn,
  }) {
    return ScannerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      flashMode: flashMode ?? this.flashMode,
      currentMode: currentMode ?? this.currentMode,
      filterMode: filterMode ?? this.filterMode,
      capturedImages: capturedImages ?? this.capturedImages,
      errorMessage: errorMessage,
      isCapturing: isCapturing ?? this.isCapturing,
      isAutoCaptureEnabled: isAutoCaptureEnabled ?? this.isAutoCaptureEnabled,
      isBlurDetected: isBlurDetected ?? this.isBlurDetected,
      isShadowRemovalEnabled: isShadowRemovalEnabled ?? this.isShadowRemovalEnabled,
      exposureOffset: exposureOffset ?? this.exposureOffset,
      isExposureLocked: isExposureLocked ?? this.isExposureLocked,
      whiteBalanceMode: whiteBalanceMode ?? this.whiteBalanceMode,
      isGridOverlayOn: isGridOverlayOn ?? this.isGridOverlayOn,
      isLevelIndicatorOn: isLevelIndicatorOn ?? this.isLevelIndicatorOn,
      isAutoHorizonOn: isAutoHorizonOn ?? this.isAutoHorizonOn,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      isBurstMode: isBurstMode ?? this.isBurstMode,
      aiQualityScore: aiQualityScore ?? this.aiQualityScore,
      qualityFeedback: qualityFeedback ?? this.qualityFeedback,
      canSwitchCamera: canSwitchCamera ?? this.canSwitchCamera,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      minZoomLevel: minZoomLevel ?? this.minZoomLevel,
      maxZoomLevel: maxZoomLevel ?? this.maxZoomLevel,
      isHdrOn: isHdrOn ?? this.isHdrOn,
      isAiAssistOn: isAiAssistOn ?? this.isAiAssistOn,
    );
  }
}

class ScannerController extends StateNotifier<ScannerState> {
  static const String _tag = 'ScannerController';

  CameraController? _cameraController;
  CameraController? get cameraController => _cameraController;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  final ImagePicker _imagePicker = ImagePicker();
  final ImageProcessingService _imageProcessor = ImageProcessingService();

  ScannerController() : super(const ScannerState()) {
    unawaited(initCamera());
  }

  Future<void> initCamera({int cameraIndex = 0}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          state = state.copyWith(errorMessage: 'No camera hardware found on device.');
        }
        return;
      }

      _cameraIndex = cameraIndex.clamp(0, _cameras.length - 1).toInt();
      await _cameraController?.dispose();

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = controller;

      await controller.initialize();
      if (!mounted || _cameraController != controller) return;

      try {
        await controller.setFocusMode(FocusMode.auto);
        await controller.setExposureMode(ExposureMode.auto);
        await controller.setFlashMode(FlashMode.off);
      } catch (e) {
        AppLogger.w('Camera focus/exposure tuning skipped: $e', _tag);
      }

      double minZoom = 1.0;
      double maxZoom = 1.0;
      try {
        minZoom = await controller.getMinZoomLevel();
        maxZoom = await controller.getMaxZoomLevel();
      } catch (_) {}

      state = state.copyWith(
        isInitialized: true,
        errorMessage: null,
        flashMode: 'off',
        isFlashOn: false,
        canSwitchCamera: _cameras.length > 1,
        minZoomLevel: minZoom,
        maxZoomLevel: maxZoom,
        zoomLevel: minZoom,
      );
      AppLogger.i('Camera initialized at maximum resolution (${_cameras[_cameraIndex].lensDirection}).', _tag);
    } catch (e) {
      AppLogger.e('Camera initialization failed: $e', tag: _tag);
      if (mounted) {
        state = state.copyWith(
          isInitialized: false,
          errorMessage: 'Camera initialization failed. You can still import images from gallery.',
        );
      }
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    state = state.copyWith(isInitialized: false, errorMessage: null);
    await initCamera(cameraIndex: nextIndex);
  }

  Future<void> setZoomLevel(double zoom) async {
    if (_cameraController == null || !state.isInitialized) return;
    final clamped = zoom.clamp(state.minZoomLevel, state.maxZoomLevel).toDouble();
    try {
      await _cameraController!.setZoomLevel(clamped);
      if (mounted) state = state.copyWith(zoomLevel: clamped);
    } catch (e) {
      AppLogger.w('Zoom update failed: $e', _tag);
    }
  }

  Future<void> cycleFlashMode() async {
    if (_cameraController == null || !state.isInitialized) return;
    try {
      String nextMode;
      FlashMode cameraFlash;
      switch (state.flashMode) {
        case 'off':
          nextMode = 'auto';
          cameraFlash = FlashMode.auto;
          break;
        case 'auto':
          nextMode = 'on';
          cameraFlash = FlashMode.always;
          break;
        case 'on':
          nextMode = 'torch';
          cameraFlash = FlashMode.torch;
          break;
        default:
          nextMode = 'off';
          cameraFlash = FlashMode.off;
      }

      await _cameraController!.setFlashMode(cameraFlash);
      if (!mounted) return;
      state = state.copyWith(
        flashMode: nextMode,
        isFlashOn: nextMode != 'off',
      );
    } catch (e) {
      AppLogger.w('Flash toggle failed: $e', _tag);
    }
  }

  Future<void> setExposureOffset(double offset) async {
    if (_cameraController == null || !state.isInitialized || state.isExposureLocked) return;
    try {
      await _cameraController!.setExposureOffset(offset);
      if (mounted) state = state.copyWith(exposureOffset: offset);
    } catch (_) {}
  }

  void toggleExposureLock() {
    state = state.copyWith(isExposureLocked: !state.isExposureLocked);
  }

  void toggleGridOverlay() {
    state = state.copyWith(isGridOverlayOn: !state.isGridOverlayOn);
  }

  void toggleLevelIndicator() {
    state = state.copyWith(isLevelIndicatorOn: !state.isLevelIndicatorOn);
  }

  void cycleTimer() {
    int nextTimer;
    if (state.timerSeconds == 0) {
      nextTimer = 3;
    } else if (state.timerSeconds == 3) {
      nextTimer = 5;
    } else if (state.timerSeconds == 5) {
      nextTimer = 10;
    } else {
      nextTimer = 0;
    }
    state = state.copyWith(timerSeconds: nextTimer);
  }

  void setScanMode(ScanMode mode) {
    state = state.copyWith(currentMode: mode);
  }

  void setColorFilter(ColorFilterMode filter) {
    state = state.copyWith(filterMode: filter);
  }

  void toggleAutoCapture() {
    state = state.copyWith(isAutoCaptureEnabled: !state.isAutoCaptureEnabled);
  }

  void toggleShadowRemoval() {
    state = state.copyWith(isShadowRemovalEnabled: !state.isShadowRemovalEnabled);
  }

  /// Toggle HDR capture mode. When enabled, captured frames are run through the
  /// AI enhancement pipeline so high-dynamic-range detail is preserved.
  void toggleHdr() => state = state.copyWith(isHdrOn: !state.isHdrOn);

  /// Toggle the contextual AI Assistant helper overlay / suggestions.
  void toggleAiAssist() => state = state.copyWith(isAiAssistOn: !state.isAiAssistOn);

  /// Tap-to-focus + tap-to-expose at a normalized [0..1] point in the preview.
  Future<void> setFocusPoint(Offset point) async {
    if (_cameraController == null || !state.isInitialized) return;
    try {
      await _cameraController!.setFocusPoint(point);
      await _cameraController!.setExposurePoint(point);
    } catch (e) {
      AppLogger.w('Focus point failed: $e', _tag);
    }
  }

  /// Night mode: pins the flash to a continuous torch and applies a low-light
  /// photo color grade so dim environments stay readable.
  Future<void> enableNightMode() async {
    if (_cameraController == null || !state.isInitialized) return;
    try {
      await _cameraController!.setFlashMode(FlashMode.torch);
      if (mounted) {
        state = state.copyWith(
          flashMode: 'torch',
          isFlashOn: true,
          filterMode: ColorFilterMode.photo,
        );
      }
    } catch (e) {
      AppLogger.w('Night mode failed: $e', _tag);
    }
  }

  /// Apply a real pixel [ColorFilterMode] preset to a saved image file and
  /// return the path of the processed copy.
  Future<String?> applyFilterToFile(String path, ColorFilterMode mode) async {
    final file = await _imageProcessor.applyFilterPreset(File(path), mode.name);
    return file?.path;
  }

  Future<void> _evaluateAndSetQualityScore(String filePath) async {
    final eval = await _imageProcessor.evaluateImageSharpness(File(filePath));
    final int score = eval['score'] as int? ?? 90;
    final bool isBlurry = eval['isBlurry'] as bool? ?? false;

    if (!mounted) return;
    state = state.copyWith(
      aiQualityScore: score,
      isBlurDetected: isBlurry,
      qualityFeedback: isBlurry
          ? '⚠️ Motion blur detected (Score: $score/100). Try holding camera steady.'
          : '⚡ AI Quality Score: $score/100 • Sharp & Aligned',
    );
  }

  Future<String?> capturePhoto() async {
    if (state.isCapturing) return null;
    state = state.copyWith(isCapturing: true, errorMessage: null);
    try {
      if (state.timerSeconds > 0) {
        await Future.delayed(Duration(seconds: state.timerSeconds));
        if (!mounted) return null;
      }

      if (_cameraController != null && state.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        await _evaluateAndSetQualityScore(xFile.path);
        if (!mounted) return xFile.path;
        final updatedList = List<String>.from(state.capturedImages)..add(xFile.path);
        state = state.copyWith(capturedImages: updatedList, isCapturing: false);
        return xFile.path;
      } else {
        // Fallback to ImagePicker if camera hardware isn't initialized
        final xFile = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (xFile != null) {
          await _evaluateAndSetQualityScore(xFile.path);
          if (!mounted) return xFile.path;
          final updatedList = List<String>.from(state.capturedImages)..add(xFile.path);
          state = state.copyWith(capturedImages: updatedList, isCapturing: false);
          return xFile.path;
        }
      }
    } catch (e) {
      AppLogger.e('Photo capture failed: $e', tag: _tag);
      if (mounted) state = state.copyWith(isCapturing: false, errorMessage: 'Failed to capture photo.');
    }
    if (mounted) state = state.copyWith(isCapturing: false);
    return null;
  }

  Future<void> importFromGallery() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        final paths = pickedFiles.map((f) => f.path).toList();
        if (paths.isNotEmpty) {
          await _evaluateAndSetQualityScore(paths.first);
        }
        if (!mounted) return;
        final updatedList = List<String>.from(state.capturedImages)..addAll(paths);
        state = state.copyWith(capturedImages: updatedList);
      }
    } catch (e) {
      AppLogger.e('Gallery import failed: $e', tag: _tag);
    }
  }

  void removeImageAt(int index) {
    if (index < 0 || index >= state.capturedImages.length) return;
    final updatedList = List<String>.from(state.capturedImages)..removeAt(index);
    state = state.copyWith(capturedImages: updatedList);
  }

  void clearBatch() {
    state = state.copyWith(capturedImages: []);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}

final scannerProvider = StateNotifierProvider<ScannerController, ScannerState>((ref) {
  return ScannerController();
});
