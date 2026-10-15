import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import 'core/localization/localization_cubit.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

class DentSpaceApp extends StatelessWidget {
  const DentSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationCubit = GetIt.instance<LocalizationCubit>();
    final themeCubit = GetIt.instance<ThemeCubit>();

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: localizationCubit),
        BlocProvider.value(value: themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocalizationCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp.router(
                title: 'DentSpace',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeMode,
                locale: locale,
                supportedLocales: const [
                  Locale('ar', ''),
                  Locale('en', ''),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: AppRouter.instance.router,
              );
            },
          );
        },
      ),
    );
  }
}