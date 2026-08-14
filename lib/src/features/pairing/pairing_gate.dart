import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/login_screen.dart';
import 'pair_device_screen.dart';
import 'pairing_controller.dart';

class PairingGate extends ConsumerWidget {
  const PairingGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing = ref.watch(pairingControllerProvider);

    return pairing.when(
      data: (shop) =>
          shop == null ? const PairDeviceScreen() : const LoginScreen(),
      error: (error, stackTrace) =>
          PairDeviceScreen(errorMessage: error.toString()),
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}
