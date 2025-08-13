import 'package:flutter/material.dart';
import 'package:pilulasdoconhecimento/home.dart';
import 'package:pilulasdoconhecimento/l10n/app_localizations.dart';
import 'package:pilulasdoconhecimento/login_page.dart'; // Import relativo ao seu projeto

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pílulas do Conhecimento - Painel Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}