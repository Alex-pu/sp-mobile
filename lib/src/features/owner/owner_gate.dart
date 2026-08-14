import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Owner')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(error.toString()),
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
