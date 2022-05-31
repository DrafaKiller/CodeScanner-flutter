## 0.3.0

Added:
* `onAccessDenied` callback

Fixed:
* `CameraController` created in the Lifecycle would not have a `CodeScannerCameraListener`
* Scanner listener wouldn't be desposed in the lifecycle


## 0.2.0

Added:
* Lifecycle states handling, on `CameraController` created internally
* Documentation to `CodeScanner`'s constructor
* Readme warning about the `CameraController` lifecycle

Changed:
* ChangeLog's format
* Pckage description

## 0.1.0

Changed:
* Callback hands `listener` instead of `controller`

## 0.0.2

Changed:
* Dart SDK version

## 0.0.1

Initial release: CodeScanner
