import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../auth/auth_controller.dart';

final productSearchProvider = StateProvider<String>((ref) => '');

final localProductsProvider = FutureProvider<List<Product>>((ref) {
  final search = ref.watch(productSearchProvider);
  return ref.watch(productRepositoryProvider).listActive(search: search);
});
