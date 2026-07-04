import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class DuckParentApp extends StatelessWidget {
  const DuckParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小黄鸭家长端',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
