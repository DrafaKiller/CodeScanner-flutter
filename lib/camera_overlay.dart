import 'package:flutter/material.dart';

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