import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
     return Scaffold(
      appBar: AppBar(
        title: const Text('Eye Spy'),
      ),
      body: const Center(
        child: Text('Hello World'),
      ),
     );

  }
 
}