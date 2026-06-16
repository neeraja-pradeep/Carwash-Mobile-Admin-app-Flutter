import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'router/app_router.dart';
import 'theme/dimens.dart';
import 'theme/theme.dart';

/// Root widget. Initialises `flutter_screenutil` against the 380×800 design
/// baseline, pins the text scale to 1.0, and mounts the GoRouter config.
class DriveDeckApp extends StatelessWidget {
  const DriveDeckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(Dimens.designWidth, Dimens.designHeight),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'DriveDeck Admin',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: appRouter,
          builder: (context, routerChild) {
            // Pin text scaling so the design renders 1:1 with ScreenUtil sizing.
            return MediaQuery.withNoTextScaling(child: routerChild ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
