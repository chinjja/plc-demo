import 'package:flutter/material.dart';
import 'package:flutter_app1/src/repo/plc.dart';
import 'package:flutter_app1/src/list/view/plc_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => Plc('192.168.1.6'),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          // primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const PlcPage(),
      ),
    );
  }
}
