import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/core_providers.dart';
import '../settings/backend_url_screen.dart';
import 'owner_controller.dart';
import 'owner_dashboard_screen.dart';
import 'owner_login_screen.dart';
import 'owner_setup_screen.dart';

class OwnerGate extends ConsumerWidget {
  const OwnerGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(ownerSessionProvider).valueOrNull;
    if (owner != null) {
      return const OwnerDashboardScreen();
    }

    final setupStatus = ref.watch(ownerSetupStatusProvider);
    return setupStatus.when(
      data: (needsSetup) =>
          needsSetup ? const OwnerSetupScreen() : const OwnerLoginScreen(),
      error: (error, stackTrace) => _OwnerConnectionError(error: error),
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

class _OwnerConnectionError extends ConsumerWidget {
  const _OwnerConnectionError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Owner')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Cannot reach backend',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Check that your backend server is running and that this phone can reach its URL.',
            ),
            const SizedBox(height: 12),
            FutureBuilder<String?>(
              future: ref.read(secureStoreProvider).readApiBaseUrl(),
              builder: (context, snapshot) {
                final url = snapshot.data ?? AppConfig.defaultApiBaseUrl;
                return Text('Current URL: $url');
              },
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const BackendUrlScreen()),
                );
                ref.invalidate(ownerSetupStatusProvider);
              },
              icon: const Icon(Icons.dns),
              label: const Text('Set backend URL'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(ownerSetupStatusProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
