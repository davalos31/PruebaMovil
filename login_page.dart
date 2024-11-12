import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:power_apps_flutter/utilities/create_user.dart';
import 'package:power_apps_flutter/utilities/home_student.dart';

class LoginPage extends StatefulWidget {
  @override
  State createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'lib/assets/escudo_universidad.png',
                height: 150,
              ),
              SizedBox(height: 20),

              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Correo
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo Universitario',
                        labelStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                        hintText: 'ejemplo@est.univalle.edu',
                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.email,
                          color: Color(0xFF950A67),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF950A67), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF950A67), width: 1),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su correo';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                        ),
                        hintText: '********',
                        hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Color(0xFF950A67),
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF950A67), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xFF950A67), width: 1),
                        ),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su contraseña';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Botones de Login y Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Color(0xFF950A67), // Color del botón
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              String email = _emailController.text;
                              String password = _passwordController.text;

                              if (email.isNotEmpty && password.isNotEmpty) {
                                // Verificar con Firebase Authentication
                                UserCredential? credenciales = await login(email, password);
                                if (credenciales != null && credenciales.user != null) {
                                  if (credenciales.user!.emailVerified) {
                                    _emailController.clear();
                                    _passwordController.clear();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => StudentPage()),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Por favor verifique su correo electrónico.')),
                                    );
                                  }
                                } else {
                                  // Autenticar con Firestore
                                  bool isFirestoreAuth = await loginWithFirestore(email, password);
                                  if (isFirestoreAuth) {
                                    _emailController.clear();
                                    _passwordController.clear();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => StudentPage()),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Correo o contraseña incorrectos.')),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          child: Text('Iniciar Sesión', style: TextStyle(color: Colors.white)),
                        ),

                        // Botón de Sign Up
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Color(0xFF950A67), // Color del botón
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            _emailController.clear();
                            _passwordController.clear();

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreateUserPage()),
                            );
                          },
                          child: Text('Sign Up', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Función con Firebase Authentication
Future<UserCredential?> login(String email, String password) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    return userCredential;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      print('Usuario no encontrado.');
    } else if (e.code == 'wrong-password') {
      print('Contraseña incorrecta.');
    } else {
      print('Error: ${e.message}');
    }
  } catch (e) {
    print('Error general: $e');
  }
  return null;
}

// Función con student en Firestore
Future<bool> loginWithFirestore(String email, String password) async {
  try {
    QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
        .collection('student')
        .where('mail', isEqualTo: email) 
        .where('password', isEqualTo: password) 
        .get();

    if (studentSnapshot.docs.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    print('Error al autenticar con Firestore: $e');
    return false;
  }
}
