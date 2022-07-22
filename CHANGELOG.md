## 0.5.0

*BREAKING CHANGES!*

Fixed:
* Widget life cycle using an internal controller.
  The widget would crash when going `inactive` and then `resumed`
* Added `removeObserver` on disposed

Removed:
* `.start()` listener function, now instantiate a new listener
* `.stop()` listener function, now use `.dispose()` to stop the listener

> The `CodeScannerCameraListener` is now disposed along with the camera and a new listener is initialized when the widget resumes. This is so the lifecycle can make sure the listener is synchronized with the current camera controller. This also means that the `onCreated` callback will be called more than once, when the widget's life cycle is resumed, with the updated camera controller and listener.

Changed:
* Separated classes into multiple files

## 0.4.0

Added:
* Exported used interfaces `ResolutionPreset` and `BarcodeFormat`
* `onError` callback

Changed:
* Default `ResolutionPreset` from `medium` to `high`, because `medium` may not be supported on all devices ([CodeScanner-flutter/issues/1](https://github.com/DrafaKiller/CodeScanner-flutter/issues/1))

## 0.3.3

Fixed:
* "Memory leak" right before the app closes

## 0.3.2

Changed:
* `onAccessDenied` return value is optional, default is `false`

## 0.3.1

Added:
* `shield.io` badges

Fixed:
* ChangeLog typos

## 0.3.0

Added:
* `onAccessDenied` callback

Fixed:
* `CameraController` created in the Lifecycle would not have a `CodeScannerCameraListener`
* Scanner listener wouldn't be disposed of in the lifecycle


## 0.2.0

Added:
* Lifecycle states handling, on `CameraController` created internally
* Documentation for `CodeScanner` constructor
* Readme warning about the `CameraController` lifecycle

Changed:
* ChangeLog's format
* Package description

## 0.1.0

Changed:
* Callback hands `listener` instead of `controller`

## 0.0.2

Changed:
* Dart SDK version

## 0.0.1

Initial release: CodeScanner
