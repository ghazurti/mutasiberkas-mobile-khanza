import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/ocr_scanner.dart';

class BatchScanPage extends StatefulWidget {
  const BatchScanPage({super.key});

  @override
  State<BatchScanPage> createState() => _BatchScanPageState();
}

class _BatchScanPageState extends State<BatchScanPage> {
  final TextEditingController _manualRmController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );
  String _mutationType = 'Kirim';
  String _scanMode = 'Barcode'; // 'Barcode' or 'Text'
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _scannerController.start();
  }

  @override
  void dispose() {
    _manualRmController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _addManualPatient(AppProvider provider) async {
    final value = _manualRmController.text.trim();
    if (value.isNotEmpty) {
      final patient = await provider.apiService.getPatientInfo(value);
      if (patient != null) {
        provider.addScannedPatient(patient);
        _manualRmController.clear();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pasien tidak ditemukan')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Scan Mutasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => provider.clearScannedPatients(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mutation Type Selector
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Kirim',
                    label: Text('Kirim ke Poli'),
                    icon: Icon(Icons.send_rounded),
                  ),
                  ButtonSegment(
                    value: 'Kembali',
                    label: Text('Kembali ke Arsip'),
                    icon: Icon(Icons.keyboard_return_rounded),
                  ),
                ],
                selected: {_mutationType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _mutationType = newSelection.first;
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: const Color(0xFF1A237E),
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),

            // Scan Mode Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Mode Scan: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Barcode'),
                    selected: _scanMode == 'Barcode',
                    onSelected: (val) {
                      if (val) setState(() => _scanMode = 'Barcode');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Teks (OCR)'),
                    selected: _scanMode == 'Text',
                    onSelected: (val) {
                      if (val) setState(() => _scanMode = 'Text');
                    },
                  ),
                ],
              ),
            ),

            // Camera Section
            VisibilityDetector(
              key: const Key('batch_scan_camera'),
              onVisibilityChanged: (visibilityInfo) {
                final visiblePercentage = visibilityInfo.visibleFraction * 100;
                if (visiblePercentage < 10 && _isVisible) {
                  _isVisible = false;
                  _scannerController.stop();
                } else if (visiblePercentage > 80 && !_isVisible) {
                  _isVisible = true;
                  if (_scanMode == 'Barcode') {
                    _scannerController.start();
                  }
                }
              },
              child: Container(
                height: 250,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                ),
                clipBehavior: Clip.antiAlias,
                child: _scanMode == 'Barcode'
                    ? MobileScanner(
                        controller: _scannerController,
                        onDetect: (capture) async {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            final String? code = barcode.rawValue;
                            if (code != null) {
                              final patient = await provider.apiService
                                  .getPatientInfo(code);
                              if (patient != null) {
                                provider.addScannedPatient(patient);
                              }
                            }
                          }
                        },
                      )
                    : OcrScanner(
                        onTextDetected: (text) async {
                          final patient = await provider.apiService
                              .getPatientInfo(text);
                          if (patient != null) {
                            provider.addScannedPatient(patient);
                          }
                        },
                      ),
              ),
            ),

            // Manual Entry Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manualRmController,
                      decoration: InputDecoration(
                        hintText: 'Input No.RM manual...',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      onSubmitted: (_) => _addManualPatient(provider),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _addManualPatient(provider),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scanned List Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Ter-scan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Badge(
                    label: Text(_mutationType),
                    backgroundColor: _mutationType == 'Kirim'
                        ? Colors.blue
                        : Colors.green,
                  ),
                ],
              ),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: provider.scannedPatients.length,
              itemBuilder: (context, index) {
                final patient = provider.scannedPatients[index];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8EAF6),
                      child: Icon(Icons.person, color: Color(0xFF1A237E)),
                    ),
                    title: Text(
                      patient.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('No.RM: ${patient.noRm}'),
                    trailing: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.scannedPatients.isEmpty
            ? null
            : () async {
                for (var patient in provider.scannedPatients) {
                  await provider.apiService.postMutation(
                    noRm: patient.noRm,
                    destination: _mutationType,
                  );
                }
                provider.clearScannedPatients();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Batch $_mutationType success!'),
                    backgroundColor: Colors.green[800],
                  ),
                );
              },
        backgroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.check, color: Colors.white),
        label: const Text(
          'Confirm Batch',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
