import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pairing_controller.dart';
import 'scan_pair_token_screen.dart';

class PairDeviceScreen extends ConsumerStatefulWidget {
  const PairDeviceScreen({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  ConsumerState<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends ConsumerState<PairDeviceScreen> {
  final _tokenController = TextEditingController();
  final _deviceLabelController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    _deviceLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairingState = ref.watch(pairingControllerProvider);
    final isLoading = pairingState.isLoading;
    final error = pairingState.hasError
        ? pairingState.error.toString()
        : widget.errorMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Link device')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 24),
            Text(
              'Connect this phone to a shop',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Use the token from the owner QR/link before signing in as a cashier.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tokenController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Pairing token'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceLabelController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Device name'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isLoading ? null : _pair,
              child: Text(isLoading ? 'Linking...' : 'Link device'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _scanToken,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR'),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _pair() {
    final token = _extractToken(_tokenController.text);
    if (token.isEmpty) {
      return;
    }
    final label = _deviceLabelController.text.trim().isEmpty
        ? 'Cashier phone'
        : _deviceLabelController.text.trim();
    ref
        .read(pairingControllerProvider.notifier)
        .acceptInvite(token: token, deviceLabel: label);
  }

  Future<void> _scanToken() async {
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanPairTokenScreen()),
    );
    if (token == null || token.isEmpty || !mounted) {
      return;
    }
    _tokenController.text = token;
  }

  String _extractToken(String input) {
    final trimmed = input.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('token')) {
      return uri.queryParameters['token']!.trim();
    }
    return trimmed;
  }
}
