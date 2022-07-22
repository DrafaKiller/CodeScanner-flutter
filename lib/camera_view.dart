import 'package:camera/camera.dart';
import 'package:code_scan/camera_overlay.dart';
import 'package:flutter/widgets.dart';

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