import 'package:flutter/material.dart';
import 'package:flutter_forms_example/register_form.dart';
import 'package:flutter_forms_example/register_form_2.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Text("Register", style: Theme.of(context).textTheme.headlineMedium),
                SizedBox(height: 16),
                // RegisterForm(),
                RegisterForm2(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
