import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/device_invite.dart';
import '../../data/models/shop.dart';
import 'owner_controller.dart';
import 'owner_inventory_screen.dart';

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(shopsProvider);
    final action = ref.watch(ownerActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(ownerSessionProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(shopsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Set up your operation',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                  'Create shops, add cashiers, then link each shop phone.'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: action.isLoading
                          ? null
                          : () => _showCreateShopSheet(context, ref),
                      icon: const Icon(Icons.add_business),
                      label: const Text('Add shop'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: action.isLoading
                          ? null
                          : () => _showCreateCashierSheet(context, ref),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add cashier'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: action.isLoading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OwnerInventoryScreen(),
                            ),
                          ),
                  icon: const Icon(Icons.inventory_2),
                  label: const Text('Manage shop stock'),
                ),
              ),
              if (action.hasError) ...[
                const SizedBox(height: 12),
                Text(
                  action.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              Text('Shops', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              shops.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('No shops yet.');
                  }
                  return Column(
                    children: [
                      for (final shop in items)
                        Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            title: Text(shop.name),
                            subtitle: Text(
                              shop.location.isEmpty
                                  ? 'No location'
                                  : shop.location,
                            ),
                            trailing: IconButton(
                              tooltip: 'Create device link',
                              icon: const Icon(Icons.qr_code_2),
                              onPressed: action.isLoading
                                  ? null
                                  : () => _createInvite(context, ref, shop),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, stackTrace) => Text(error.toString()),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createInvite(
    BuildContext context,
    WidgetRef ref,
    Shop shop,
  ) async {
    final invite = await ref.read(ownerActionProvider.notifier).createInvite(
          shopId: shop.id,
          deviceLabel: '${shop.name} phone',
        );
    if (!context.mounted || invite == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => _DeviceInviteDialog(invite: invite),
    );
  }

  Future<void> _showCreateShopSheet(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add shop', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Shop name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(ownerActionProvider.notifier).createShop(
                      name: nameController.text.trim(),
                      location: locationController.text.trim(),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Save shop'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    locationController.dispose();
  }

  Future<void> _showCreateCashierSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shops = ref.read(shopsProvider).valueOrNull ?? const <Shop>[];
    if (shops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a shop first.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final pinController = TextEditingController();
    var selectedShopId = shops.first.id;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add cashier',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedShopId,
                items: [
                  for (final shop in shops)
                    DropdownMenuItem(value: shop.id, child: Text(shop.name)),
                ],
                onChanged: (shopId) {
                  if (shopId != null) {
                    setState(() => selectedShopId = shopId);
                  }
                },
                decoration: const InputDecoration(labelText: 'Shop'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Cashier name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Cashier PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.read(ownerActionProvider.notifier).createCashier(
                        name: nameController.text.trim(),
                        pin: pinController.text.trim(),
                        shopId: selectedShopId,
                      );
                  Navigator.of(context).pop();
                },
                child: const Text('Save cashier'),
              ),
            ],
          ),
        ),
      ),
    );
    nameController.dispose();
    pinController.dispose();
  }
}

class _DeviceInviteDialog extends StatelessWidget {
  const _DeviceInviteDialog({required this.invite});

  final DeviceInvite invite;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Device link created'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop: ${invite.shopName}'),
          const SizedBox(height: 12),
          const Text('Token'),
          SelectableText(invite.token),
          const SizedBox(height: 12),
          const Text('Link'),
          SelectableText(invite.link),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: invite.link));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Link copied.')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy link'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
