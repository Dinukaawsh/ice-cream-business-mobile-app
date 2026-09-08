import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "../models/sale.dart";
import "../services/api_service.dart";
import "../widgets/app_toast.dart";
import "../widgets/auth_ui.dart";
import "../widgets/confirm_dialog.dart";

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<CustomerItem> _customers = [];
  var _loading = true;
  var _filter = "all";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final customers = await widget.api.fetchCustomers(
        type: _filter == "all" ? null : _filter,
      );
      if (!mounted) return;
      setState(() => _customers = customers);
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addCustomer() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final address = TextEditingController();
    var type = "shop";

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text("Add customer"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: "shop", label: Text("Shop")),
                    ButtonSegment(value: "person", label: Text("Person")),
                  ],
                  selected: {type},
                  onSelectionChanged: (value) =>
                      setLocal(() => type = value.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: "Address"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;
    if (!mounted) return;
    if (name.text.trim().isEmpty) {
      showErrorToast(context, "Name is required");
      return;
    }

    try {
      await widget.api.createCustomer(
        type: type,
        name: name.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        address: address.text.trim().isEmpty ? null : address.text.trim(),
      );
      if (!mounted) return;
      showSuccessToast(context, "Customer created");
      await _load();
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  Future<void> _delete(CustomerItem customer) async {
    final ok = await showConfirmDialog(
      context,
      title: "Delete customer?",
      message: "Remove ${customer.name}?",
      confirmLabel: "Delete",
      isDanger: true,
    );
    if (!ok) return;
    try {
      await widget.api.deleteCustomer(id: customer.id);
      if (!mounted) return;
      showSuccessToast(context, "Customer deleted");
      await _load();
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        context,
        error.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.frost,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Customers",
          style: GoogleFonts.fraunces(
            fontWeight: FontWeight.w700,
            color: AuthColors.blueberry,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        backgroundColor: AuthColors.primary,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text("Add"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "all", label: Text("All")),
                ButtonSegment(value: "shop", label: Text("Shops")),
                ButtonSegment(value: "person", label: Text("People")),
              ],
              selected: {_filter},
              onSelectionChanged: (value) {
                setState(() => _filter = value.first);
                _load();
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _customers.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text("No customers yet")),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _customers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final customer = _customers[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFFDBEAFE),
                                      child: Icon(
                                        customer.type == "shop"
                                            ? Icons.store
                                            : Icons.person,
                                        color: AuthColors.primaryDeep,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            customer.type == "shop"
                                                ? "Shop · credit LKR ${customer.returnCredit.toStringAsFixed(0)} · due LKR ${customer.outstandingBalance.toStringAsFixed(0)}"
                                                : "Person",
                                            style: const TextStyle(
                                              color: AuthColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _delete(customer),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
