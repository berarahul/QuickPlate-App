import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/app_exports.dart';

class ScanCameraOverlay extends StatelessWidget {
  final MobileScannerController controller;
  final bool isActive;
  final Function(BarcodeCapture) onDetect;
  final VoidCallback onScanFromGallery;

  const ScanCameraOverlay({
    super.key,
    required this.controller,
    required this.isActive,
    required this.onDetect,
    required this.onScanFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isActive)
          MobileScanner(
            controller: controller,
            onDetect: onDetect,
          )
        else
          Container(color: Colors.black),
        // Dark vignette with cut-out hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(color: Colors.transparent),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Scanner frame with corners
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.transparent,
                width: 0,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: _buildCorners(),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Align the table QR code within the frame',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onScanFromGallery,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Scan QR from Gallery',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const size = 36.0;
    const thick = 4.0;
    final color = AppColors.primary;
    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(width: size, height: thick, color: color),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(width: thick, height: size, color: color),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(width: size, height: thick, color: color),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(width: thick, height: size, color: color),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(width: size, height: thick, color: color),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(width: thick, height: size, color: color),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(width: size, height: thick, color: color),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(width: thick, height: size, color: color),
      ),
    ];
  }
}
