import 'package:flutter/material.dart';
import 'package:code_scan/code_scan.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({ Key? key }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TickerProviderStateMixin {
  String? code;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: code == null ?
          CodeScanner(
            onScan: (code, details, controller) => setState(() => this.code = code),
            onScanAll: (codes, controller) => print('Codes: ' + codes.map((code) => code.rawValue).toString()),
            formats: const [ BarcodeFormat.qrCode ],
            once: true,
          ) : 
          GestureDetector(
            onTap: () => setState(() => code = null),
            child: Container(
              color: Colors.transparent,
              child: Center(child: Text(code!)),
            ),
          ),
      ),
    );
  }
}