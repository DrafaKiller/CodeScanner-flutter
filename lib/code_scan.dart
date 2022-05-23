library code_scan;

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import 'package:code_scan/utils/image.dart';
import 'package:code_scan/utils/list.dart';
import 'package:thread/thread.dart';

class CodeScanner extends StatefulWidget {
  final CameraLensDirection direction;
  final ResolutionPreset resolution;
  final List<BarcodeFormat> formats;
  final Duration scanInterval;
  final bool once;

  final void Function(CameraController controller)? onCreated;
  final void Function(String? code, Barcode details, CameraController controller)? onScan;
  final void Function(List<Barcode> barcodes, CameraController controller)? onScanAll;

  final Widget? loading;
  final Widget? overlay;
  
  const CodeScanner({
    super.key,
    this.direction = CameraLensDirection.back,
    this.resolution = ResolutionPreset.medium,
    this.formats = const [ BarcodeFormat.all ],
    this.scanInterval = const Duration(seconds: 1),
    this.once = false,

    this.onCreated,
    this.onScan,
    this.onScanAll,

    this.loading,
    this.overlay,
  });

  @override
  State<CodeScanner> createState() => _CodeScannerState();
}

class _CodeScannerState extends State<CodeScanner> {
  CameraController? controller;
  CodeScannerCameraListener? listener;

  @override
  void initState() {
    super.initState();
    availableCameras().then((cameras) async {
      final camera = cameras.firstWhereOrNull((camera) => camera.lensDirection == widget.direction) ?? cameras.first;

      final controller = CameraController(camera, widget.resolution, enableAudio: false);
      await controller.initialize();

      widget.onCreated?.call(controller);
      setState(() => this.controller = controller);

      listener = CodeScannerCameraListener(
        this.controller!,
        onScan: widget.onScan,
        onScanAll: widget.onScanAll,
        formats: widget.formats,
        interval: widget.scanInterval,
        once: widget.once,
      );
    });
    
  }

  @override
  void dispose() {
    listener?.dispose();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) return widget.loading ?? Container();
    return CodeScannerCameraView(
      controller: controller!,
      overlay: widget.overlay,
    );
  }
}

class CodeScannerCameraView extends StatelessWidget {
  final CameraController controller;
  final Widget? overlay;

  const CodeScannerCameraView({
    super.key,
    required this.controller,
    this.overlay,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      overlay ?? Container(),
      CameraPreview(controller),
    ]);
  }
}

class CodeScannerCameraListener {
  final CameraController controller;
  final imageController = StreamController<CameraImage>();
  final void Function(String? code, Barcode details, CameraController controller)? onScan;
  final void Function(List<Barcode> barcodes, CameraController controller)? onScanAll;
  final List<BarcodeFormat> formats;
  final Duration interval;
  final bool once;
  final Thread thread;

  CodeScannerCameraListener(
    this.controller,
    {
      this.onScan,
      this.onScanAll,
      this.formats = const [ BarcodeFormat.all ],
      this.interval = const Duration(seconds: 1),
      this.once = false,
      Thread? thread,
    }
  ) : this.thread = thread ?? defaultThread() {
    start();

    this.thread.emit('formats', formats);

    imageController.stream
      .throttleTime(interval, leading: false, trailing: true)
      .listen((image) => this.thread.emit('image', CameraImageData(image, controller.description)));
    
    this.thread.on('barcodes', (List<Barcode> barcodes) {
      onScan?.call(barcodes.first.rawValue, barcodes.first, controller);
      onScanAll?.call(barcodes, controller);
    });
  }

  void start() {
    controller.startImageStream((CameraImage image) {
      if (!imageController.isClosed) imageController.add(image);
    });
  }

  void stop() {
    controller.stopImageStream();
  }

  void dispose() {
    imageController.close();
    thread.stop();
  }

  static Thread defaultThread() {
    return Thread((emitter) {
      BarcodeScanner? scanner;

      emitter.on('formats', (List<BarcodeFormat> formats) {
        scanner = BarcodeScanner(formats: formats);
      });

      emitter.on('image', (CameraImageData data) async {
        if (scanner == null) return;

        final cropWidth = data.image.width * 0.5;
        final cropHeight = cropWidth * 0.5;
        final cropX = data.image.width * 0.25;
        final cropY = data.image.height * 0.5 - cropHeight / 2;

        final inputImage = data.image
          //.crop(cropX.toInt(), cropY.toInt(), cropWidth.toInt(), cropHeight.toInt())
          .toInputImage(data.description);

        print(Isolate.current.debugName);

        final barcodes = await scanner!.processImage(inputImage);
        if (barcodes.isNotEmpty) emitter.emit('barcodes', barcodes);
      });
    });
  }
}