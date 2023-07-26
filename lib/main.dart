import 'package:flutter/material.dart';
import 'package:searchdialog/multiple/multiple_dialog.dart';
import 'package:searchdialog/single/searchdialog.dart';

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
   final List<String> listitems = ['A', 'B', 'C', 'D', 'E'];
  final TextEditingController controllerbar = TextEditingController();

  void removeItem(String item) {
    setState(() {
      listitems.remove(item);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SearchDialog(
              controllerBar: controllerbar,
              listItens: listitems,
              onDeleteItem: removeItem, 
            ),
            const SizedBox(height: 20,),
            MultipleDialog(
              listItems: listitems,
            ),
          ],
        ),
      ),
    );
  }
}
