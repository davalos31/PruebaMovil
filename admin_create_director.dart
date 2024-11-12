import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:power_apps_flutter/utilities/components/combo_box.dart';
import 'package:power_apps_flutter/utilities/components/main_color.dart';
import 'package:power_apps_flutter/utilities/components/snack_bar.dart';
import 'package:power_apps_flutter/utilities/components/text_form_field_model.dart';

class CreateDirector extends StatefulWidget {
  const CreateDirector({super.key});

  @override
  State<CreateDirector> createState() => _CreateDirectorState();
}

class _CreateDirectorState extends State<CreateDirector> {
  final TextEditingController nameController = TextEditingController();
  final List<String> careers = [
    'Ing. Sistemas',
    'Ing. Industrial',
    'Ing. Civil',
    'Lic. Administración',
    'Lic. Economía',
    'Medicina',
    'Arquitectura',
    'Derecho'
  ];
  String? selectedCareer;

  // Método para registrar en Firestore
  Future<void> registerDirector() async {
    if (nameController.text.isNotEmpty && selectedCareer != null) {
      try {
        await FirebaseFirestore.instance.collection('director').add({
          'name': nameController.text,
          'career': selectedCareer,
        });
        showAnimatedSnackBar(context, 'Registro Exitoso');
        // Limpiar los campos después de registrar
        nameController.clear();
        setState(() {
          selectedCareer = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, complete todos los campos'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Registrar Director',
          style: TextStyle(fontSize: 30, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF950A67),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Campo de Nombre
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: const Icon(
                        Icons.person,
                        color: mainColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: mainColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: mainColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ComboBox para seleccionar carrera
                  ComboBox(
                    itemsList: careers,
                    hintText: 'Carrera',
                    selectedValue: selectedCareer,
                    icon: const Icon(
                      Icons.school,
                      color: mainColor,
                    ),
                    onChanged: (String? value) {
                      setState(() {
                        selectedCareer = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Botón de registro
                  ElevatedButton(
                    onPressed: registerDirector,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF950A67),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: Colors.grey.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 40,
                      ),
                    ),
                    child: const Text(
                      'Registrar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
