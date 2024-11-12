import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:power_apps_flutter/utilities/components/combo_box.dart';  // Importar ComboBox

class CreateUserPage extends StatefulWidget {
  @override
  State createState() {
    return _CreateUserState();
  }
}

class _CreateUserState extends State<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedCareer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'lib/assets/escudo_universidad.png', 
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Registro de Usuario",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF950A67), 
                    ),
                  ),
                  const SizedBox(height: 16),
                  formulario(),
                  const SizedBox(height: 20),
                  btnSignUp(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget formulario() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          buildEmail(),
          const SizedBox(height: 12),
          buildPassword(),
          const SizedBox(height: 12),
          buildCareerDropdown(), // ComboBox carrera
        ],
      ),
    );
  }

  Widget buildEmail() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: "Correo Universitario",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: Color(0xFF950A67)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: Color(0xFF950A67)),
        ),
        prefixIcon: Icon(
          Icons.email,
          color: Color(0xFF950A67),
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese un correo';
        }
        if (!value.endsWith('@est.univalle.edu')) {
          return 'El correo debe ser de la universidad (@est.univalle.edu)';
        }
        return null;
      },
    );
  }

  Widget buildPassword() {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: "Contraseña",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: Color(0xFF950A67)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: Color(0xFF950A67)),
        ),
        prefixIcon: Icon(
          Icons.lock,
          color: Color(0xFF950A67),
        ),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese una contraseña';
        }
        final passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
        if (!passwordRegExp.hasMatch(value)) {
          return 'La contraseña debe tener al menos 8 caracteres, una mayúscula, un número y un carácter especial';
        }
        return null;
      },
    );
  }

  Widget buildCareerDropdown() {
    return ComboBox(
      itemsList: [
        'Arquitectura', 
        'Economía', 
        'Ing. Sistemas', 
        'Ing. Civil', 
        'Medicina', 
        'Derecho'
      ],
      hintText: 'Carrera',
      icon: Icon(
        Icons.school,
        color: Color(0xFF950A67),
      ),
      selectedValue: _selectedCareer,
      onChanged: (newValue) {
        setState(() {
          _selectedCareer = newValue;
        });
      },
    );
  }

  Widget btnSignUp() {
    return FractionallySizedBox(
      widthFactor: 0.6,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: Color(0xFF950A67),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () async {
          if (_formKey.currentState?.validate() ?? false) {
            String email = _emailController.text;
            String password = _passwordController.text;

            if (email.isNotEmpty && password.isNotEmpty && _selectedCareer != null) {
              UserCredential? credenciales =
                  await createU(email, password, _selectedCareer!, context);
              if (credenciales != null) {
                if (credenciales.user != null) {
                  await credenciales.user!.sendEmailVerification();
                  Navigator.of(context).pop();
                }
              }
            }
          }
        },
        child: Text("Registrarse", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// Función para crear el usuario en Firestore y Firebase Authentication
Future<UserCredential?> createU(
    String email, String password, String career, BuildContext context) async {
  try {
    // Verificar si el correo ya existe en Firestore
    QuerySnapshot existingUser = await FirebaseFirestore.instance
        .collection('student')
        .where('mail', isEqualTo: email)
        .get();

    if (existingUser.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El correo ya está registrado.')),
      );
      return null; 
    }

    // Si no existe en Firestore, proceder con Firebase Authentication
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // Guardar correo, carrera y contraseña en Firestore
    await FirebaseFirestore.instance
        .collection('student')
        .doc(userCredential.user?.uid)
        .set({
      'mail': email,
      'password': password, // encriptar la contraseña(falta)
      'career': career,
    });

    return userCredential;
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    if (e.code == 'email-already-in-use') {
      errorMessage = 'El correo ya está en uso en Firebase Authentication.';
    } else if (e.code == 'weak-password') {
      errorMessage = 'La contraseña es demasiado débil.';
    } else {
      errorMessage = 'Error: ${e.message}';
    }

    // Mostrar error en la interfaz con SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error general: $e')),
    );
  }
  return null;
}
