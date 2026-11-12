import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';
import '../services/gps_location_service.dart';
import '../constants/parking_location_config.dart';
import '../services/parking_transaction_service.dart';

class ClientScanQRPage extends StatelessWidget {
  const ClientScanQRPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFE3EDFF),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 105,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Scan QR Parkir',
            style: TextStyle(
              color: AppTheme.darkBlue,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Pindai kode QR di area parkir ICT atau PU '
            'untuk mencatat kendaraan masuk dan keluar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey, height: 1.6, fontSize: 13),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Validasi Lokasi GPS',
                        style: TextStyle(
                          color: AppTheme.darkBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Pemindaian QR hanya dapat dilakukan '
                        'dalam radius ${ParkingLocationConfig.radiusInMeters.toStringAsFixed(0)} meter '
                        'dari lokasi parkir ICT atau PU.',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _ScanOption(
            icon: Icons.login_rounded,
            title: 'Kendaraan Masuk',
            description: 'Catat waktu masuk parkir',
            onTap: () => _openScanner(context, 'MASUK'),
          ),
          const SizedBox(height: 14),
          _ScanOption(
            icon: Icons.logout_rounded,
            title: 'Kendaraan Keluar',
            description: 'Catat waktu keluar parkir',
            onTap: () => _openScanner(context, 'KELUAR'),
          ),
          const SizedBox(height: 22),
          const Text(
            'Arahkan kamera ke kode QR parkir.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  static Future<void> _openScanner(BuildContext context, String action) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _QRScannerPage(action: action)),
    );

    if (!context.mounted || result == null) return;

    // VALIDASI FORMAT QR
    final parts = result
        .split('|')
        .map((part) => part.trim().toUpperCase())
        .toList();

    final isValid =
        parts.length == 3 &&
        parts[0] == 'PARKSPOT' &&
        ['ICT', 'PU'].contains(parts[1]) &&
        parts[2] == action;

    final messenger = ScaffoldMessenger.of(context);

    if (!isValid) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('QR tidak valid atau tidak sesuai aktivitas.'),
        ),
      );
      return;
    }

    final parkingLocation = ParkingLocationConfig.getLocation(parts[1]);

    if (parkingLocation == null) return;

    final gpsService = GpsLocationService();

    try {
      // TAHAP 1: MEMERIKSA GPS
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 30),
          content: Text('Sedang memeriksa lokasi GPS...'),
        ),
      );

      final position = await gpsService.getCurrentPosition();

      final distance = gpsService.calculateDistance(
        currentPosition: position,
        targetLatitude: parkingLocation.latitude,
        targetLongitude: parkingLocation.longitude,
      );

      final isAllowed = gpsService.isWithinRadius(
        distance: distance,
        radiusInMeters: ParkingLocationConfig.radiusInMeters,
      );

      if (!context.mounted) return;

      messenger.hideCurrentSnackBar();

      // TAHAP 2: MENOLAK JIKA DI LUAR RADIUS
      if (!isAllowed) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            content: Text(
              'Akses ditolak! Jarak kamu '
              '${distance.round()} meter dari parkiran ${parts[1]}.',
            ),
          ),
        );
        return;
      }

      // TAHAP 3: MENYIMPAN TRANSAKSI FIREBASE
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 30),
          content: Text('Lokasi valid. Sedang menyimpan transaksi...'),
        ),
      );

      final transactionService = ParkingTransactionService();

      if (action == 'MASUK') {
        await transactionService.enterParking(parts[1]);
      } else {
        await transactionService.exitParking(parts[1]);
      }

      if (!context.mounted) return;

      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          content: Text(
            action == 'MASUK'
                ? 'Berhasil! Kendaraan masuk parkiran ${parts[1]}.'
                : 'Berhasil! Kendaraan keluar parkiran ${parts[1]}.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      messenger.hideCurrentSnackBar();

      String message = error.toString();

      message = message.replaceFirst('Bad state: ', '');

      if (message.contains('permission-denied')) {
        message = 'Akses database ditolak. Periksa Firestore Rules.';
      }

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          content: Text(message),
        ),
      );
    }
  }
}

class _QRScannerPage extends StatefulWidget {
  final String action;

  const _QRScannerPage({required this.action});

  @override
  State<_QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<_QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();

  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR ${widget.action}'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_hasScanned) return;

                for (final barcode in capture.barcodes) {
                  final value = barcode.rawValue;

                  if (value != null && value.trim().isNotEmpty) {
                    _hasScanned = true;
                    Navigator.pop(context, value);
                    break;
                  }
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  size: 36,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 8),
                Text(
                  'Arahkan kamera ke QR ${widget.action} parkir.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _controller.toggleTorch(),
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('Lampu Flash'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ScanOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 27),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.darkBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(description),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.primaryBlue,
        ),
        onTap: onTap,
      ),
    );
  }
}
