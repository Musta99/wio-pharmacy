import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'sheet_scaffold.dart';

class RxViewerSheet extends StatelessWidget {
  const RxViewerSheet({
    super.key,
    required this.patientName,
    required this.prescriptionUrl,
  });
  final String patientName;
  final String prescriptionUrl;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      maxHeightFactor: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF0E1B33),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Rx: $patientName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Fidelity pharmaceutical validation interface.',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: prescriptionUrl,
                  fit: BoxFit.contain,
                  placeholder:
                      (_, __) => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(40),
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.black26,
                        ),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
