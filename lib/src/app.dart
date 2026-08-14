import 'package:flutter/material.dart';

import 'features/onboarding/role_selection_screen.dart';
import 'theme/app_theme.dart';

class SmartPosApp extends StatelessWidget {
  const SmartPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart POS',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RoleSelectionScreen(),
    );
  }
}
