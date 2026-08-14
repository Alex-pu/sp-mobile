import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/storage/secure_store.dart';
import '../models/printer_config.dart';
import '../models/receipt.dart';
import 'esc_pos_receipt_builder.dart';

class PrinterRepository {
  PrinterRepository(this._secureStore);

  final SecureStore _secureStore;

  Future<PrinterConfig> readConfig() async {
    final saved = await _secureStore.readPrinterConfig();
    return PrinterConfig.fromJson(saved);
  }

  Future<void> saveConfig(PrinterConfig config) {
    return _secureStore.savePrinterConfig(
      transport: config.transport,
      name: config.name,
      address: config.address,
      paperWidth: config.paperWidth,
    );
  }

  Future<List<PairedPrinter>> pairedPrinters() async {
    await _ensureBluetoothPermission();
    final enabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!enabled) {
      throw StateError('Turn on Bluetooth first.');
    }
    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) {
      throw StateError('Bluetooth permission is required.');
    }
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map(
          (device) => PairedPrinter(
            name: device.name,
            address: device.macAdress,
          ),
        )
        .toList();
  }

  Future<void> printReceipt(Receipt receipt) async {
    final config = await readConfig();
    if (!config.isConfigured) {
      throw StateError('Printer is not configured.');
    }

    final bytes = EscPosReceiptBuilder(
      paperWidth: config.paperWidth,
    ).build(receipt);

    if (config.transport == 'bluetooth') {
      await _sendBluetooth(bytes, config);
      return;
    }

    throw StateError('Unsupported printer transport: ${config.transport}');
  }

  Future<void> _sendBluetooth(List<int> bytes, PrinterConfig config) async {
    await _ensureBluetoothPermission();
    final enabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!enabled) {
      throw StateError('Turn on Bluetooth first.');
    }

    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) {
      throw StateError('Bluetooth permission is required.');
    }

    var connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: config.address,
      );
    }
    if (!connected) {
      throw StateError('Could not connect to ${config.name}.');
    }

    final printed = await PrintBluetoothThermal.writeBytes(bytes);
    if (!printed) {
      throw StateError('Could not send receipt to ${config.name}.');
    }
  }

  Future<void> _ensureBluetoothPermission() async {
    final status = await Permission.bluetoothConnect.request();
    if (!status.isGranted) {
      throw StateError('Bluetooth permission is required.');
    }
  }
}
