import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // 1. Initialize Controller
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Firebase Config'),
        actions: [
          // 🎯 FIX 1: Toggle Flash (Listen to controller value)
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              // In v5+, state is 'MobileScannerState'
              final isTorchOn = state.torchState == TorchState.on;

              // Hide if unavailable
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),

          // 🎯 FIX 2: Switch Camera (Listen to controller value)
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              // In v5+, use 'cameraDirection' instead of 'cameraFacingState'
              final isBack = state.cameraDirection == CameraFacing.back;

              return IconButton(
                icon: Icon(isBack ? Icons.camera_rear : Icons.camera_front),
                onPressed: () => _controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              // 🎯 Found a code!
              _controller.stop(); // Stop scanning
              if (mounted) {
                Navigator.pop(context, barcode.rawValue); // Return data
              }
              break;
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}