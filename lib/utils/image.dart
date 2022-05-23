import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

extension CameraImageToInputImage on CameraImage {
  Uint8List getBytes() {
    final allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }  

  InputImage toInputImage(CameraDescription camera) {
    final inputImageData = InputImageData(
      size: Size(width.toDouble(), height.toDouble()),
      imageRotation: InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg,
      inputImageFormat: InputImageFormatValue.fromRawValue(format.raw) ?? InputImageFormat.nv21,
      planeData: planes.map((Plane plane) => InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      )).toList(),
    );
    return InputImage.fromBytes(bytes: getBytes(), inputImageData: inputImageData);
  }
}

class CameraImageData {
  final CameraImage image;
  final CameraDescription description;
  CameraImageData(this.image, this.description);
}

/*
extension InputImageCrop on InputImage {
  InputImage crop(int x, int y, int width, int height) {
    final croppedData = InputImageData(
      size: inputImageData!.size,
      imageRotation: inputImageData!.imageRotation,
      inputImageFormat: inputImageData!.inputImageFormat,
      planeData: inputImageData!.planeData!.map((InputImagePlaneMetadata planeData) => InputImagePlaneMetadata(
        bytesPerRow: width * planeData.bytesPerRow ~/ planeData.width!,
        height: height,
        width: width,
      )).toList(),
    );
    
    final croppedBytes = Uint8List.fromList(bytes!.map((byte) => byte).toList());
    
    return InputImage.fromBytes(
      bytes: croppedBytes,
      inputImageData: croppedData,
    );
  }
}
*/