import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/isbn.dart';

/// Ouvre un scanner et renvoie l'ISBN lu (ou null si on abandonne).
/// Remplaçable dans les tests.
typedef ScannerIsbn = Future<String?> Function(BuildContext context);

/// Le scan par appareil photo existe sur Android, iPhone, Mac et dans le
/// navigateur, mais pas dans l'application Windows (saisie à la main).
bool get scannerDisponible =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Scanner réel, avec l'appareil photo.
Future<String?> scannerIsbnCamera(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute<String>(builder: (_) => const ScannerIsbnScreen()),
);

/// Écran de scan : on vise le code-barres au dos du livre ; dès qu'un ISBN
/// valide est lu, l'écran se ferme et le renvoie.
class ScannerIsbnScreen extends StatefulWidget {
  const ScannerIsbnScreen({super.key});

  @override
  State<ScannerIsbnScreen> createState() => _ScannerIsbnScreenState();
}

class _ScannerIsbnScreenState extends State<ScannerIsbnScreen> {
  final _controleur = MobileScannerController(
    formats: const [BarcodeFormat.ean13],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _fini = false;

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  void _detecte(BarcodeCapture capture) {
    for (final code in capture.barcodes) {
      final brut = code.rawValue;
      if (!_fini && brut != null && estCodeBarresLivre(brut)) {
        _fini = true;
        Navigator.pop(context, normaliserIsbn(brut));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scanner un livre')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controleur,
            onDetect: _detecte,
            errorBuilder: (context, erreur) => _Indisponible(
              detail: erreur.errorDetails?.message ?? erreur.errorCode.name,
            ),
          ),
          // Cadre de visée.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: Text(
              'Visez le code-barres au dos du livre',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                shadows: [Shadow(blurRadius: 6, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Indisponible extends StatelessWidget {
  const _Indisponible({required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 56,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              const Text(
                'Appareil photo indisponible',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Autorisez l\'accès à l\'appareil photo, ou saisissez '
                'l\'ISBN à la main.\n($detail)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Saisir l\'ISBN à la main'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
