import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:what_to_click/src/injectable.dart';
import 'package:what_to_click/src/ui/router.dart';

class WhatToClickApp extends StatelessWidget {
  WhatToClickApp({super.key});

  final appRouter = sl<AppRouter>();

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: appRouter.config(
          deepLinkBuilder: (deeplink) {
            return DeepLink.none;
          },
        ),
        restorationScopeId: 'app',
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''),
        ],
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context)!.appTitle,
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
      );
}
