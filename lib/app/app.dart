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
      // On some startup paths (notably the Android emulator with Impeller) the
      // render surface briefly reports a 0×0 size. ScreenUtil would then scale
      // every `.sp`/`.w`/`.h`/`.r` value to 0, tripping Flutter asserts
      // (`fontSize > 0`, infinite-height, unsized RenderBox …) so the UI fails
      // to lay out. `ensureScreenSize` defers the first frame until the view
      // reports a real size, so scaling is always computed against valid metrics.
      ensureScreenSize: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Drivey Admin',
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
