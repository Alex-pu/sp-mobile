import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_base_url.dart';
import '../../core/providers/core_providers.dart';

class BackendUrlScreen extends ConsumerStatefulWidget {
  const BackendUrlScreen({super.key});

  @override
  ConsumerState<BackendUrlScreen> createState() => _BackendUrlScreenState();
}

class _BackendUrlScreenState extends ConsumerState<BackendUrlScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await ref.read(secureStoreProvider).readApiBaseUrl();
    if (!mounted) {
      return;
    }
    _controller.text = saved ?? AppConfig.defaultApiBaseUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backend URL')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Backend server URL',
                hintText: 'http://192.168.1.50:5000',
                errorText: _error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Text(
              'Use the server address reachable from this phone. The app will add /api automatically when needed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final normalized = normalizeApiBaseUrl(_controller.text);
    if (normalized == null) {
      setState(() => _error = 'Enter a valid URL.');
      return;
    }

    await ref.read(secureStoreProvider).saveApiBaseUrl(normalized);
    ref.invalidate(apiClientProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backend set to $normalized')),
    );
    Navigator.of(context).pop(true);
  }
}
