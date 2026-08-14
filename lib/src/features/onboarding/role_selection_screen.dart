import 'package:flutter/material.dart';

import '../owner/owner_gate.dart';
import '../pairing/pairing_gate.dart';
import '../settings/backend_url_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chui POS'),
        actions: [
          IconButton(
            tooltip: 'Backend URL',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BackendUrlScreen()),
            ),
            icon: const Icon(Icons.dns),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Text(
              'Chui POS',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to use this app.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            _RoleCard(
              icon: Icons.storefront,
              title: 'Business owner',
              subtitle: 'Create your shop, add cashiers, and link shop phones.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerGate()),
              ),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.point_of_sale,
              title: 'Cashier',
              subtitle:
                  'Link this phone to a shop, then sign in with your PIN.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PairingGate()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
