library code_scan;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'package:code_scan/utils/image.dart';
import 'package:code_scan/utils/list.dart';

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
  /// Default: `front`
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
  /// * min
  /// * max
  /// 
  /// Default: `medium`
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
  final void Function(CameraController controller)? onCreated;
  final void Function(String? code, Barcode details, CodeScannerCameraListener listener)? onScan;
  final void Function(List<Barcode> barcodes, CodeScannerCameraListener listener)? onScanAll;
  
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
    this.resolution = ResolutionPreset.medium,
    this.formats = const [ BarcodeFormat.all ],
    this.scanInterval = const Duration(seconds: 1),
    this.once = false,
    this.aspectRatio,

    this.onCreated,
    this.onScan,
    this.onScanAll,
    this.onAccessDenied,

    this.loading,
    this.overlay,
  });

  @override
  State<CodeScanner> createState() => _CodeScannerState();
}

class _CodeScannerState extends State<CodeScanner> with WidgetsBindingObserver {
  CameraController? controller;
  CodeScannerCameraListener? listener;

  bool retry = true;
  bool initialized = false;
  bool isInternalController = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameraController();
  }

  @override
  void dispose() {
    listener?.dispose();
    controller?.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!isInternalController) return;

    if (state == AppLifecycleState.inactive) {
      final CameraController? cameraController = controller;
      if (cameraController == null || !cameraController.value.isInitialized) return;
      cameraController.dispose();
      setState(() => this.controller = null);
    } else if (state == AppLifecycleState.resumed && retry && initialized && controller == null) {
      initialized = false;
      _initCameraController();
    }
  }

  Future<void> _initCameraController() async {
    final CameraController controller;
    final widgetController = widget.controller;
    
    if (widgetController != null) {
      isInternalController = false;
      controller = widgetController;
    } else {
      isInternalController = true;
      controller = await _createCameraController();
      try {
        await controller.initialize();
      } on CameraException catch (error) {
        controller.dispose();
        retry = widget.onAccessDenied?.call(error, controller) ?? false;
        initialized = true;
        return;
      }
    }

    widget.onCreated?.call(controller);
    setState(() => this.controller = controller);

    if (listener != null) listener!.dispose();
    listener = CodeScannerCameraListener(
      this.controller!,
      onScan: widget.onScan,
      onScanAll: widget.onScanAll,
      formats: widget.formats,
      interval: widget.scanInterval,
      once: widget.once,
    );

    initialized = true;
  }
  
  Future<CameraController> _createCameraController() async {
    final cameras = await availableCameras();
    final camera = cameras.firstWhereOrNull((camera) => camera.lensDirection == widget.direction) ?? cameras.first;
    return CameraController(camera, widget.resolution, enableAudio: false);
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) return widget.loading ?? Container();
    return CodeScannerCameraView(
      controller: controller!,
      overlay: widget.overlay,
      aspectRatio: widget.aspectRatio,
    );
  }
}

/// Widget to show a camera with an overlay, this widget tries to expand.
class CodeScannerCameraView extends StatelessWidget {
  final CameraController controller;
  final Widget? overlay;
  final double? aspectRatio;

  const CodeScannerCameraView({
    super.key,
    required this.controller,
    this.overlay,
    this.aspectRatio,
  });
  
  @override
  Widget build(BuildContext context) {
    final cameraAspectRatio = controller.value.aspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth * cameraAspectRatio,
                child: CameraPreview(controller),
              ),
            ),
          ),
          overlay ?? CodeScannerOverlay(constraints.maxWidth, constraints.minHeight),
        ],
      ),
    );
  }
}

/// Create a camera listener to plug it with any camera controller, to scan for codes
class CodeScannerCameraListener {
  final CameraController controller;
  final imageController = StreamController<CameraImage>();
  final BarcodeScanner scanner;
  final bool once;
  
  final void Function(String? code, Barcode details, CodeScannerCameraListener listener)? onScan;
  final void Function(List<Barcode> barcodes, CodeScannerCameraListener listener)? onScanAll;

  CodeScannerCameraListener(
    this.controller,
    {
      List<BarcodeFormat> formats = const [ BarcodeFormat.all ],
      Duration interval = const Duration(milliseconds: 500),
      this.once = false,
      
      this.onScan,
      this.onScanAll,
    }
  ) : this.scanner = BarcodeScanner(formats: formats) {
    start();
    imageController.stream
      .throttleTime(interval, leading: false, trailing: true)
      .listen((image) => _onImage(image));
  }

  void start() {
    if (!controller.value.isStreamingImages) {
      controller.startImageStream((CameraImage image) {
        if (!imageController.isClosed) imageController.add(image);
      });
    }
  }

  Future<void> stop() async {
    await imageController.close();
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    } 
  }

  Future<void> dispose() async {
    await imageController.close();
  }

  void _onImage(CameraImage image) {
    if (!controller.value.isStreamingImages) return;
    if (onScan == null && onScanAll == null) return;

    /*
    final cropWidth = image.width * 0.5;
    final cropHeight = cropWidth * 0.5;
    final cropX = image.width * 0.25;
    final cropY = image.height * 0.5 - cropHeight / 2;
    */

    final inputImage = image
      //.crop(cropX.toInt(), cropY.toInt(), cropWidth.toInt(), cropHeight.toInt())
      .toInputImage(controller.description);

    scanner.processImage(inputImage).then((barcodes) => _onImageProcessed(barcodes));
  }

  void _onImageProcessed(List<Barcode> barcodes) async {
    if (!controller.value.isStreamingImages || barcodes.isEmpty) return;

    if (once) await stop();
    onScan?.call(barcodes.first.rawValue, barcodes.first, this);
    onScanAll?.call(barcodes, this);
  }
}

/// Default overlay displayed on top of the camera
class CodeScannerOverlay extends StatelessWidget {
  final double width;
  final double height;

  const CodeScannerOverlay(this.width, this.height, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            width: width * 0.8,
            height: 0.8,
            color: Colors.redAccent.withOpacity(0.4),
          ),
        ),
        Center(
          child: Container(
            width: width * 0.8,
            height: width * 0.7,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black.withOpacity(0.3), width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.srcOut),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(decoration: BoxDecoration(
                color: Colors.black,
                backgroundBlendMode: BlendMode.dstIn,
              )),
              Center(
                child: Container(
                  width: width * 0.8,
                  height: width * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ]
          ),
        ),
      ],
    );
  }
}