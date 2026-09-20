import 'package:flutter/material.dart';
import 'package:leditor/features/editor/presentation/pages/editor_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Editor',
      theme: ThemeData.dark(useMaterial3: true),
      home: const EditorPage(),
    );
  }
}