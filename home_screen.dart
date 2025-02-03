import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget{
  const HomeScreen({super.key});


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Fitting Room'),
    ),
    body: const Center(
      child: Text('Welcome To The Fitting Room'),
      ),
    );
  }
}

