import "package:flutter/material.dart";

import "../models/sale.dart";
import "../services/api_service.dart";
import "../widgets/app_chrome.dart";
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

  Future<void> _recordPayment(CustomerItem customer) async {
    if (customer.outstandingBalance <= 0) {
      showErrorToast(context, "This customer has no unpaid amount");
      return;
    }
    final amount = TextEditingController(
      text: customer.outstandingBalance.toStringAsFixed(0),
    );
    final notes = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Record payback"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${customer.name} unpaid: LKR ${customer.outstandingBalance.toStringAsFixed(0)}",
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: "Amount paid"),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(
                  labelText: "Note (optional)",
                ),
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
            child: const Text("Continue"),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final value = double.tryParse(amount.text.trim()) ?? 0;
    if (value <= 0) {
      if (!mounted) return;
      showErrorToast(context, "Enter a valid amount");
      return;
    }
    if (!mounted) return;
    final ok = await showConfirmDialog(
      context,
      title: "Record this payment?",
      message:
          "Take LKR ${value.toStringAsFixed(0)} from ${customer.name} against unpaid bills?",
      confirmLabel: "Record payment",
    );
    if (!ok) return;
    try {
      final message = await widget.api.recordCustomerPayment(
        customerId: customer.id,
        amount: value,
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      );
      if (!mounted) return;
      showSuccessToast(context, message);
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
    return AppPage(
      title: "Customers",
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        backgroundColor: AuthColors.primary,
        foregroundColor: Colors.white,
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
                        ? AppEmptyState(
                            icon: Icons.people_outline,
                            title: "No customers yet",
                            message: "Add a shop or person to track credit and returns.",
                            actionLabel: "Add customer",
                            onAction: _addCustomer,
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: _customers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final customer = _customers[index];
                              return AppSurfaceCard(
                                child: Row(
                                  children: [
                                    AppIconBadge(
                                      icon: customer.type == "shop"
                                          ? Icons.storefront_rounded
                                          : Icons.person_rounded,
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
                                              fontSize: 16,
                                              color: AuthColors.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: [
                                              AppStatusChip(
                                                label: customer.type == "shop"
                                                    ? "Shop"
                                                    : "Person",
                                              ),
                                              if (customer.outstandingBalance > 0 ||
                                                  customer.returnCredit > 0) ...[
                                                if (customer.outstandingBalance > 0)
                                                  AppStatusChip(
                                                    label:
                                                        "Due LKR ${customer.outstandingBalance.toStringAsFixed(0)}",
                                                    tone: AppChipTone.warning,
                                                  ),
                                                if (customer.returnCredit > 0)
                                                  AppStatusChip(
                                                    label:
                                                        "Credit LKR ${customer.returnCredit.toStringAsFixed(0)}",
                                                    tone: AppChipTone.success,
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (customer.outstandingBalance > 0)
                                      IconButton(
                                        tooltip: "Record payback",
                                        onPressed: () =>
                                            _recordPayment(customer),
                                        icon: const Icon(
                                          Icons.payments_outlined,
                                          color: Color(0xFF15803D),
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
