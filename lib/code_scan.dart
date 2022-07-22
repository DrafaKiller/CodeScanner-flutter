library code_scan;

import 'dart:async';

import 'package:code_scan/camera_listener.dart';
import 'package:code_scan/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'package:code_scan/utils/list.dart';

export 'package:camera/camera.dart' show ResolutionPreset;
export 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart' show BarcodeFormat;

/// # Code Scanner
/// 
/// A flexible code scanner for QR codes, barcodes and many others. Using [Google's ML Kit](https://developers.google.com/ml-kit/vision/barcode-scanning). Use it as a Widget with a camera or use the methods provided, with a camera controller..
/// 
/// ## Features
/// 
/// * Scan Linear and 2D formats: QR Code, Barcode, ...
/// * Widget with integrated camera
/// * Listen for callbacks with every code scanned
/// * Choose which formats to scan
/// * Overlay the camera preview with a custom view
/// * Camera lifecycle
/// 
/// ## Scannable Formats
/// 
/// * Aztec
/// * Codabar
/// * Code 39
/// * Code 93
/// * Code 128
/// * Data Matrix
/// * EAN-8
/// * EAN-13
/// * ITF
/// * PDF417
/// * QR Code
/// * UPC-A
/// * UPC-E
class CodeScanner extends StatefulWidget {
  final CameraController? controller;

  /// Which camera to use:
  /// * front
  /// * back
  /// * external
  /// 
  /// Default: `back`
  final CameraLensDirection direction;

  /// Quality of the camera:
  /// * low
  /// * medium
  /// * high
  /// * very high
  /// * ultra
  /// 
  /// or
  /// 
  /// * max
  /// 
  /// Setting a lower resolution preset may not support scanning features on some devices.
  /// It's recommended to use the highest quality preset available, if performance is not an issue.
  /// 
  /// Default: `high`
  final ResolutionPreset resolution;

  /// List of the scannable formats:
  /// * Aztec
  /// * Codabar
  /// * Code 39
  /// * Code 93
  /// * Code 128
  /// * Data Matrix
  /// * EAN-8
  /// * EAN-13
  /// * ITF
  /// * PDF417
  /// * QR Code
  /// * UPC-A
  /// * UPC-E
  final List<BarcodeFormat> formats;

  /// Duration of delay between scans, to prevent lag.
  final Duration scanInterval;

  /// Whether or not, when a code is scanned, the controller should close and no longer scan.
  /// 
  /// Default: `false`
  final bool once;
  final double? aspectRatio;

  /// Called whenever a controller is created.
  /// 
  /// A new controller is created when initializing the widget and when the life cycle is resumed.
  final void Function(CameraController controller, CodeScannerCameraListener listener)? onCreated;
  final void Function(String? code, Barcode details, CodeScannerCameraListener listener)? onScan;
  final void Function(List<Barcode> barcodes, CodeScannerCameraListener listener)? onScanAll;
  final void Function(Object error, CodeScannerCameraListener listener)? onError;
  
  /// Called whenever camera access permission is denied by the user.
  /// 
  /// Return `true` to retry, else `false`. Not setting this callback, will automatically never retry.
  /// 
  /// Careful when retrying, this permission could have been rejected automatically, if you keep trying then it will silently spam the permission in a cycle. The `error` given can be useful to check this.
  /// 
  /// Another approach would be to request the permission preemptively, before creating this widget, so it will never be needed to handle it here.
  final bool? Function(CameraException error, CameraController controller)? onAccessDenied;

  /// Widget to show before the cameras are initialized.
  final Widget? loading;

  /// Widget to overlay on top of the camera.
  /// 
  /// Default: `CodeScannerOverlay()`
  final Widget? overlay;
  
  /// # Code Scanner
  /// 
  /// A flexible code scanner for QR codes, barcodes and many others. Using [Google's ML Kit](https://developers.google.com/ml-kit/vision/barcode-scanning). Use it as a Widget with a camera or use the methods provided, with a camera controller.
  /// 
  /// ## Features
  /// 
  /// * Scan Linear and 2D formats: QR Code, Barcode, ...
  /// * Widget with integrated camera
  /// * Listen for callbacks with every code scanned
  /// * Choose which formats to scan
  /// * Overlay the camera preview with a custom view
  /// 
  /// ## Simple Usage
  /// ```dart
  /// CodeScanner(
  ///   onScan: (code, details, controller) => ...,
  ///   formats: [ BarcodeFormat.qrCode ],
  ///   once: true,
  ///   onAccessDenied: (error, controller) {
  ///     Navigator.of(context).pop();
  ///     return false;
  ///   },
  /// )
  /// ```
  const CodeScanner({
    super.key,
    this.controller,
    this.direction = CameraLensDirection.back,
    this.resolution = ResolutionPreset.high,
    this.formats = const [ BarcodeFormat.all ],
    this.scanInterval = const Duration(seconds: 1),
    this.once = false,
    this.aspectRatio,

    this.onCreated,
    this.onScan,
    this.onScanAll,
    this.onAccessDenied,
    this.onError,

    this.loading,
    this.overlay,
  });

  @override
  State<CodeScanner> createState() => _CodeScannerState();
}

class _CodeScannerState extends State<CodeScanner> with WidgetsBindingObserver {
  CameraController? controller;
  CodeScannerCameraListener? listener;

  bool retry = false;
  bool get isInitialized => controller?.value.isInitialized ?? false;
  bool get isInternalController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeCamera();
    super.dispose();
  }

  Future<void> disposeCamera() async {
    await listener?.dispose();
    if (isInternalController) await controller?.dispose();
    if (mounted) setState(() {
      listener = null;
      controller = null;
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isInternalController) return;
    if (state == AppLifecycleState.inactive && isInitialized) {
      disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    await disposeCamera();

    final CameraController controller;
    if (isInternalController) {
      controller = await _createCameraController();
      try {
        await controller.initialize();
      } on CameraException catch (error) {
        retry = widget.onAccessDenied?.call(error, controller) ?? false;
        return;
      }
    } else {
      controller = widget.controller!;
    }

    setState(() {
      this.controller = controller;
      this.listener = CodeScannerCameraListener(
        this.controller!,
        onScan: widget.onScan,
        onScanAll: widget.onScanAll,
        formats: widget.formats,
        interval: widget.scanInterval,
        once: widget.once,
      );
    });

    widget.onCreated?.call(controller, listener!);
  }
  
  Future<CameraController> _createCameraController() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhereOrNull((camera) => camera.lensDirection == widget.direction) ?? cameras.first;
    return CameraController(camera, widget.resolution, enableAudio: false);
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) return widget.loading ?? Container();
    return CodeScannerCameraView(
      controller: controller!,
      overlay: widget.overlay,
      aspectRatio: widget.aspectRatio,
    );
  }
}