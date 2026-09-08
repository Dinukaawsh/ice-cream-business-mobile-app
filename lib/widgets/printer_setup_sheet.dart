import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../services/thermal_printer_service.dart';

const _printerMessages = <String, String>{
  'printer.selectPrinter': 'Select Bluetooth printer',
  'printer.setupHint':
      'Pair the printer in phone Bluetooth settings first. Disconnect it from laptops/PCs before printing from the phone.',
  'printer.notPaired':
      'No paired printers found. Pair the printer in phone Settings → Bluetooth.',
  'printer.bluetoothOff': 'Turn on Bluetooth to print.',
  'printer.permissionDenied':
      'Allow Bluetooth permission for Ice Cream in phone settings.',
  'printer.connectFailed': 'Could not connect to the printer.',
  'printer.printFailed': 'Print failed. Try again.',
  'printer.renderFailed': 'Could not prepare the receipt for printing.',
  'printer.loadFailed': 'Could not load paired printers.',
  'printer.unsupported':
      'Direct Bluetooth print is not available on this device.',
};

String printerMessage(String code) =>
    _printerMessages[code] ?? code.replaceFirst('printer.', '');

Future<SavedPrinter?> showPrinterSetupSheet(BuildContext context) {
  return showModalBottomSheet<SavedPrinter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFEEF6FF),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _PrinterSetupSheet(),
  );
}

class _PrinterSetupSheet extends StatefulWidget {
  const _PrinterSetupSheet();

  @override
  State<_PrinterSetupSheet> createState() => _PrinterSetupSheetState();
}

class _PrinterSetupSheetState extends State<_PrinterSetupSheet> {
  final _service = ThermalPrinterService.instance;
  List<BluetoothInfo> _devices = [];
  bool _loading = true;
  String? _errorCode;
  String? _savingMac;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorCode = null;
    });
    try {
      final devices = await _service.listPairedPrinters();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } on ThermalPrinterException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorCode = error.code;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorCode = 'printer.loadFailed';
        _loading = false;
      });
    }
  }

  Future<void> _select(BluetoothInfo device) async {
    if (_savingMac != null) return;

    setState(() => _savingMac = device.macAdress);
    try {
      final saved = SavedPrinter(
        name: device.name,
        mac: device.macAdress,
      );
      await _service.savePrinter(saved);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorCode = 'printer.loadFailed');
    } finally {
      if (mounted) setState(() => _savingMac = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listHeight = MediaQuery.sizeOf(context).height * 0.55;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              printerMessage('printer.selectPrinter'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              printerMessage('printer.setupHint'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorCode != null)
              Column(
                children: [
                  Text(
                    printerMessage(_errorCode!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _load,
                    child: const Text('Retry'),
                  ),
                ],
              )
            else
              SizedBox(
                height: listHeight,
                child: ListView.separated(
                  itemCount: _devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final saving = _savingMac == device.macAdress;
                    final likelyPrinter =
                        ThermalPrinterService.instance.looksLikePrinter(
                      device.name,
                    );

                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: saving ? null : () => _select(device),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: likelyPrinter
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFBFDBFE),
                              width: likelyPrinter ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.print_rounded,
                                color: likelyPrinter
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      device.macAdress,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (saving)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF2563EB),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
