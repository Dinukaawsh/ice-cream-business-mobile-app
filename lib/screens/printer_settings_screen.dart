import 'package:flutter/material.dart';

import '../services/thermal_printer_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/printer_setup_sheet.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  SavedPrinter? _printer;
  var _loading = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final printer = await ThermalPrinterService.instance.getSavedPrinter();
    if (!mounted) return;
    setState(() {
      _printer = printer;
      _loading = false;
    });
  }

  Future<void> _changePrinter() async {
    final printer = await showPrinterSetupSheet(context);
    if (printer == null || !mounted) return;
    setState(() => _printer = printer);
    showSuccessToast(context, 'Printer saved');
  }

  Future<void> _clearPrinter() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Clear printer?',
      message: 'You will need to select a printer again before printing.',
      confirmLabel: 'Clear',
      isDanger: true,
    );
    if (!ok) return;
    await ThermalPrinterService.instance.clearSavedPrinter();
    if (!mounted) return;
    setState(() => _printer = null);
    showSuccessToast(context, 'Printer cleared');
  }

  Future<void> _testPrint() async {
    if (_busy) return;
    var printer = _printer;
    if (printer == null) {
      await _changePrinter();
      printer = _printer;
      if (printer == null) return;
    }

    setState(() => _busy = true);
    try {
      if (!mounted) return;
      showSuccessToast(context, 'Connecting to printer...');
      await ThermalPrinterService.instance.printTestPage(mac: printer.mac);
      if (!mounted) return;
      showSuccessToast(context, 'Test print sent');
    } on ThermalPrinterException catch (error) {
      if (!mounted) return;
      showErrorToast(context, printerMessage(error.code));
    } catch (_) {
      if (!mounted) return;
      showErrorToast(context, 'Print failed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = ThermalPrinterService.isSupported;

    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth printer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _printer == null
                            ? 'No printer selected'
                            : 'Saved printer: ${_printer!.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (_printer != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _printer!.mac,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Uses the same ESC/POS Bluetooth path as Bakery. Disconnect the printer from any laptop before testing.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!supported)
                  Text(
                    printerMessage('printer.unsupported'),
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: _busy ? null : _changePrinter,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: Text(
                      _printer == null ? 'Select printer' : 'Change printer',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _testPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('Test print'),
                  ),
                  if (_printer != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _busy ? null : _clearPrinter,
                      child: const Text('Clear saved printer'),
                    ),
                  ],
                ],
              ],
            ),
    );
  }
}
