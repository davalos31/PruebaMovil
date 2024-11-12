import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Estudiante')),
      body: Center(child: Text('Página de Estudiante')),
    );
  }
}

