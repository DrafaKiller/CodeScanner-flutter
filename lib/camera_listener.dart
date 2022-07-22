import 'dart:async';

import 'package:camera/camera.dart';
import 'package:code_scan/utils/image.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:rxdart/rxdart.dart';

/// Create a camera listener to plug it with any camera controller, to scan for codes
class CodeScannerCameraListener {
  final CameraController controller;
  final imageController = StreamController<CameraImage>();
  final BarcodeScanner scanner;
  final bool once;
  
  final void Function(String? code, Barcode details, CodeScannerCameraListener listener)? onScan;
  final void Function(List<Barcode> barcodes, CodeScannerCameraListener listener)? onScanAll;
  final void Function(Object error, CodeScannerCameraListener listener)? onError;

  CodeScannerCameraListener(
    this.controller,
    {
      List<BarcodeFormat> formats = const [ BarcodeFormat.all ],
      Duration interval = const Duration(seconds: 1),
      this.once = false,
      
      this.onScan,
      this.onScanAll,
      this.onError,
    }
  ) : this.scanner = BarcodeScanner(formats: formats) {
    imageController.stream
      .throttleTime(interval, leading: false, trailing: true)
      .listen((image) async {
        try {
          final barcodes = await processImage(image);
          
          if (!controller.value.isStreamingImages || barcodes.isEmpty) return;

          if (once) await dispose();
          onScan?.call(barcodes.first.rawValue, barcodes.first, this);
          onScanAll?.call(barcodes, this);
        } catch (error) {
          if (onError != null) {
            onError?.call(error, this);
          } else {
            rethrow;
          }
        }
      });
      
    controller.startImageStream((CameraImage image) {
      if (!imageController.isClosed) imageController.add(image);
    });
  }

  Future<void> dispose() async {
    if (controller.value.isStreamingImages) await controller.stopImageStream();
    await imageController.close();
    await scanner.close();
  }

  Future<List<Barcode>> processImage(CameraImage image) async =>
    await scanner.processImage(image.toInputImage(controller.description));
}