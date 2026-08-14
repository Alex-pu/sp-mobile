import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/printer_config.dart';
import '../receipts/receipt_providers.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  static const _transport = 'bluetooth';
  static const _paperWidth = 48;

  List<PairedPrinter> _pairedPrinters = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.bluetooth_connected),
                    title: Text('Pair in Android Bluetooth first'),
                    subtitle: Text(
                      'Then select the paired 80mm printer from this list.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isScanning ? null : _loadPairedPrinters,
                    icon: _isScanning
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isScanning
                          ? 'Checking paired devices...'
                          : 'Refresh paired printers',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_pairedPrinters.isEmpty)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline),
                      title: Text('No paired printers loaded'),
                      subtitle: Text(
                        'Refresh after pairing the printer in Android settings.',
                      ),
                    ),
                  for (final printer in _pairedPrinters)
                    ListTile(
                      leading: const Icon(Icons.print),
                      title: Text(printer.name),
                      subtitle: Text(printer.address),
                      trailing: printer.address == _addressController.text
                          ? const Icon(Icons.check_circle)
                          : null,
                      onTap: () => _selectPrinter(printer),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    readOnly: true,
                    decoration:
                        const InputDecoration(labelText: 'Printer name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Bluetooth MAC address',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.receipt),
                    title: Text('80mm receipt paper'),
                    subtitle: Text(
                      'Format width is fixed for the common 80mm printer.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save printer'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _load() async {
    final config = await ref.read(printerRepositoryProvider).readConfig();
    if (!mounted) {
      return;
    }
    setState(() {
      _nameController.text = config.name;
      _addressController.text = config.address;
      _isLoading = false;
    });
    await _loadPairedPrinters();
  }

  Future<void> _loadPairedPrinters() async {
    setState(() => _isScanning = true);
    try {
      final printers =
          await ref.read(printerRepositoryProvider).pairedPrinters();
      if (!mounted) {
        return;
      }
      setState(() => _pairedPrinters = printers);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _selectPrinter(PairedPrinter printer) {
    setState(() {
      _nameController.text = printer.name;
      _addressController.text = printer.address;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      if (_addressController.text.trim().isEmpty) {
        throw StateError('Select a paired printer first.');
      }
      await ref.read(printerRepositoryProvider).saveConfig(
            PrinterConfig(
              transport: _transport,
              name: _nameController.text.trim(),
              address: _addressController.text.trim(),
              paperWidth: _paperWidth,
            ),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Printer saved')));
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
