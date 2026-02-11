import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/ocr_scanner.dart';

class ShelfMappingPage extends StatefulWidget {
  const ShelfMappingPage({super.key});

  @override
  State<ShelfMappingPage> createState() => _ShelfMappingPageState();
}

class _ShelfMappingPageState extends State<ShelfMappingPage> {
  final TextEditingController _shelfController = TextEditingController();
  final TextEditingController _manualRmController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );
  String _scanMode = 'Barcode'; // 'Barcode' or 'Text'
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _scannerController.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      _shelfController.text = provider.currentShelf;
    });
  }

  void _autoSuggestShelf(String noRm) {
    if (noRm.length >= 2) {
      final suggestion = noRm.substring(noRm.length - 2);
      _shelfController.text = suggestion;
      final provider = Provider.of<AppProvider>(context, listen: false);
      provider.setCurrentShelf(suggestion);
    }
  }

  void _mapManual(AppProvider provider) async {
    final noRm = _manualRmController.text.trim();

    // Auto suggest if empty
    if (_shelfController.text.isEmpty) {
      _autoSuggestShelf(noRm);
    }

    final shelf = _shelfController.text.trim();

    if (shelf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi ID Rak terlebih dahulu')),
      );
      return;
    }

    if (noRm.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silakan isi No.RM manual')));
      return;
    }

    final success = await provider.apiService.updateShelf(noRm, shelf);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RM $noRm berhasil dipetakan ke $shelf')),
      );
      _manualRmController.clear();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal melakukan pemetaan')));
    }
  }

  @override
  void dispose() {
    _shelfController.dispose();
    _manualRmController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapping Rak RM')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input Lokasi Rak',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _shelfController,
              decoration: InputDecoration(
                hintText: 'Misal: 87 atau A-01',
                prefixIcon: const Icon(Icons.door_sliding_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onChanged: (value) => provider.setCurrentShelf(value),
            ),
            const SizedBox(height: 24),

            // Scan Mode Selector
            Row(
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
            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  VisibilityDetector(
                    key: const Key('shelf_mapping_camera'),
                    onVisibilityChanged: (visibilityInfo) {
                      final visiblePercentage =
                          visibilityInfo.visibleFraction * 100;
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
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
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
                                    // Auto suggest shelf from RM digits if empty
                                    if (_shelfController.text.isEmpty) {
                                      _autoSuggestShelf(code);
                                    }

                                    final success = await provider.apiService
                                        .updateShelf(
                                          code,
                                          _shelfController.text,
                                        );
                                    if (success) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'RM $code mapped to ${_shelfController.text}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            )
                          : OcrScanner(
                              onTextDetected: (text) async {
                                if (_shelfController.text.isEmpty) {
                                  _autoSuggestShelf(text);
                                }
                                final success = await provider.apiService
                                    .updateShelf(text, _shelfController.text);
                                if (success) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'RM $text mapped to ${_shelfController.text}',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _scanMode == 'Barcode'
                        ? 'Pindai barcode berkas'
                        : 'Pindai tulisan No.RM (OCR)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            const Text(
              'Gagal Pindai? Input Manual No.RM',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualRmController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan No.RM...',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    onSubmitted: (_) => _mapManual(provider),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _mapManual(provider),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
