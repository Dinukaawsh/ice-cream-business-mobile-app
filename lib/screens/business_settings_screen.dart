import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/brand.dart';
import '../models/business_settings.dart';
import '../services/api_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/bill_receipt_card.dart';
import '../widgets/confirm_dialog.dart';

class BusinessSettingsScreen extends StatefulWidget {
  const BusinessSettingsScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final _businessName = TextEditingController();
  final _ownerName = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  BusinessSettings? _settings;
  var _loading = true;
  var _saving = false;
  var _logoBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final settings = await widget.api.fetchBusinessSettings();
      if (!mounted) return;
      _apply(settings);
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(BusinessSettings settings) {
    _settings = settings;
    _businessName.text = settings.businessName;
    _ownerName.text = settings.ownerName ?? '';
    _address.text = settings.address;
    _phone.text = settings.phone;
    _email.text = settings.email ?? '';
    setState(() {});
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > 700000) {
      if (!mounted) return;
      showErrorToast(context, 'Logo is too large. Pick a smaller image.');
      return;
    }

    final mime = file.mimeType ?? 'image/jpeg';
    final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';

    setState(() => _logoBusy = true);
    try {
      final settings = await widget.api.uploadBusinessLogo(dataUri: dataUri);
      if (!mounted) return;
      _apply(settings);
      showSuccessToast(context, 'Logo uploaded');
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _clearLogo() async {
    final ok = await showConfirmDialog(
      context,
      title: 'Remove logo?',
      message: 'Your business logo will be removed from settings.',
      confirmLabel: 'Remove',
      isDanger: true,
    );
    if (!ok) return;

    setState(() => _logoBusy = true);
    try {
      final settings = await widget.api.removeBusinessLogo();
      if (!mounted) return;
      _apply(settings);
      showSuccessToast(context, 'Logo removed');
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final settings = await widget.api.updateBusinessSettings(
        businessName: _businessName.text.trim(),
        ownerName: _ownerName.text.trim(),
        address: _address.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
      );
      if (!mounted) return;
      _apply(settings);
      showSuccessToast(context, 'Business settings saved');
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = _settings?.logoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business settings'),
        actions: [
          TextButton(
            onPressed: _loading || _saving
                ? null
                : () {
                    final settings = BusinessSettings(
                      businessName: _businessName.text.trim().isEmpty
                          ? Brand.name
                          : _businessName.text.trim(),
                      ownerName: _ownerName.text.trim().isEmpty
                          ? null
                          : _ownerName.text.trim(),
                      address: _address.text.trim(),
                      phone: _phone.text.trim(),
                      email: _email.text.trim().isEmpty
                          ? null
                          : _email.text.trim(),
                      logoUrl: logoUrl,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BillPreviewScreen(settings: settings),
                      ),
                    );
                  },
            child: const Text('Preview bill'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'These details appear at the top of bills. Logo is optional and not printed.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFDBEAFE),
                        backgroundImage: (logoUrl != null
                                ? NetworkImage(logoUrl)
                                : const AssetImage(Brand.logoAsset))
                            as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _logoBusy || _saving ? null : _pickLogo,
                            icon: _logoBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.cloud_upload_outlined),
                            label: Text(
                              logoUrl == null ? 'Upload logo' : 'Change logo',
                            ),
                          ),
                          if (logoUrl != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed:
                                  _logoBusy || _saving ? null : _clearLogo,
                              child: const Text('Remove'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _businessName,
                  decoration: const InputDecoration(labelText: 'Business name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ownerName,
                  decoration: const InputDecoration(labelText: 'Owner name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Business email (optional)',
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving || _logoBusy ? null : _save,
                  child: Text(_saving ? 'Saving...' : 'Save settings'),
                ),
              ],
            ),
    );
  }
}

class BillPreviewScreen extends StatelessWidget {
  const BillPreviewScreen({super.key, required this.settings});

  final BusinessSettings settings;

  @override
  Widget build(BuildContext context) {
    final sampleItems = [
      const BillLineItem(
        productName: 'Vanilla scoop',
        variantName: 'Single',
        quantity: 2,
        unitPrice: 250,
      ),
      const BillLineItem(
        productName: 'Chocolate cone',
        variantName: 'Regular',
        quantity: 1,
        unitPrice: 350,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Bill preview')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Sample layout — real sales will use the same header, totals, and thank-you footer.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
          const SizedBox(height: 16),
          BillReceiptCard(
            settings: settings,
            billNumberLabel: 'Sale #1001',
            saleDate: DateTime.now(),
            items: sampleItems,
            totalAmount: 850,
            customerName: 'Walk-in customer',
            channel: 'Walk-in',
            paidAmount: 850,
            isPreview: true,
          ),
        ],
      ),
    );
  }
}
