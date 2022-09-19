[![Pub.dev package](https://img.shields.io/badge/pub.dev-code__scan-blue)](https://pub.dev/packages/code_scan)
[![GitHub repository](https://img.shields.io/badge/GitHub-CodeScanner--flutter-blue?logo=github)](https://github.com/DrafaKiller/CodeScanner-flutter)

# Code Scanner

A flexible code scanner for QR codes, barcodes and many others. Using [Google's ML Kit](https://developers.google.com/ml-kit/vision/barcode-scanning). Use it as a Widget with a camera or use the methods provided, with a camera controller.

> **Note:** This package is only **Android and iOS** compatible. It's having issues with mislabeling compatible platforms by pub.dev.
> 
> Google's ML Kit is only implemented for mobile.

## Features

* Scan Linear and 2D formats: QR Code, Barcode, ...
* Widget with integrated camera
* Listen for callbacks with every code scanned
* Choose which formats to scan
* Overlay the camera preview with a custom view
* Camera lifecycle

## Scannable Formats

* Aztec
* Codabar
* Code 39
* Code 93
* Code 128
* Data Matrix
* EAN-8
* EAN-13
* ITF
* PDF417
* QR Code
* UPC-A
* UPC-E

## Getting started

Install it using pub:
```
flutter pub add code_scan
```

And import the package:
```dart
import 'package:code_scan/code_scan.dart';
```

## Usage

```dart
CodeScanner(
    onScan: (code, details, controller) => setState(() => this.code = code),
    onScanAll: (codes, controller) => print('Codes: ' + codes.map((code) => code.rawValue).toString()),
    formats: [ BarcodeFormat.qrCode ],
    once: true,
)
``` 

Add callbacks for events:
```dart
CodeScanner(
    onScan: (code, details, controller) => ...,
    onScanAll: (codes, controller) => ...,
    onCreated: (controller) => ...,
)
```

Set `loading` and `overlay` widgets, although you can use the default overlay:
```dart
CodeScanner(
    loading: Center(child: CircularProgressIndicator()),
    overlay: Center(child: Text('Scanning...')),
)
```

Choose how the widget should react:
```dart
CodeScanner(
    direction: CameraLensDirection.back,
    resolution: ResolutionPreset.medium,
    formats: const [ BarcodeFormat.all ],
    scanInterval: const Duration(seconds: 1),
    aspectRatio: 480 / 720, // height / width
    once: false,
)
```

The default behavior of the widget is to fill the screen or parent widget, but you can choose the aspect ratio.

You can use the camera view with your camera controller, without having the scanning widget:
```dart
final cameraController = CameraController();

CodeScannerCameraView(
    controller: cameraController,
)
```

### Caution

If you use your camera controller, it's recommended that you be responsible to control camera resources.

Manage it yourself using [the lifecycle](https://pub.dev/packages/camera#handling-lifecycle-states) or make sure it's already being managed by some other widget.

## Methods provided

Create a camera listener and plug it with any camera controller, to scan for codes:
```dart
final cameraController = CameraController();

final listener = CodeScannerCameraListener(
    cameraController,
    
    formats: const [ BarcodeFormat.all ],
    interval: const Duration(milliseconds: 500),
    once: false,
    
    onScan: (code, details, controller) => ...,
    onScanAll: (codes, controller) => ...,
);
```

Stop the listener whenever you want:
```dart
listener.stop();
```

## GitHub

The package code is available on Github: [Flutter - CodeScanner](https://github.com/DrafaKiller/CodeScanner-flutter)
