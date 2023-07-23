import 'package:flutter/material.dart';
import 'package:searchdialog/multiple/mutiple_searchdialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController controllerBar = TextEditingController();
    List<String> lista = [
      'Lorenzo',
      'Bonora',
      'Bettega',
      'Lorenzo2',
      'Bonora2',
      'Bettega2',
      'Lorenzo3',
      'Bonora3',
      'Bettega3',
      'Lorenzo4',
      'Bonora4',
      'Bettega4',
    ];
    return const Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: MultipleSearchDialog(
            )
          ),
        ],
      ),
    );
  }
}
