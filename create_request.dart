import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:power_apps_flutter/utilities/components/combo_box.dart';
import 'package:power_apps_flutter/utilities/components/date_picker.dart';
import 'package:power_apps_flutter/utilities/components/main_color.dart';
import 'package:power_apps_flutter/utilities/components/snack_bar.dart';
import 'package:power_apps_flutter/utilities/components/text_form_field_model.dart';
import 'package:power_apps_flutter/utilities/components/toast.dart';

class CreateRequest extends StatefulWidget {
  const CreateRequest({Key? key}) : super(key: key);

  @override
  CreateRequestState createState() => CreateRequestState();
}

class CreateRequestState extends State<CreateRequest> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ciController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cellPhonelController = TextEditingController();

  String? selectedCarrera;
  String? selectedFileName;
  File? selectedFile;
  Uint8List? selectedBytes;
  String? fileUrl;
  DateTime? selectedDate;
  List<String> fileNames = [];
  List<String> fileUrls = [];
  List<Uint8List> fileBytes = [];

  List<String> carreras = ['ISI', 'MDC', 'UI', 'Arquitectura'];

  Future<void> selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg', 'docx'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (kIsWeb) {
            fileBytes.add(file.bytes!);
            fileNames.add(file.name);
          } else {
            final path = file.path;
            if (path != null) {
              setState(() {
                selectedFile = File(path);
                fileNames.add(file.name);
              });
            }
          }
        }
        print('Archivos seleccionados: $fileNames');
      } else {
        print('No se seleccionaron archivos.');
      }
    } catch (e) {
      Toast.show(context, e.toString());
    }
  }

  Future<void> addRequest() async {
    if (nameController.text.isEmpty ||
        ciController.text.isEmpty ||
        selectedCarrera == null ||
        fileNames.isEmpty) {
      print("Por favor, complete todos los campos.");
      return;
    }

    try {
      fileUrls.clear();

      for (int i = 0; i < fileNames.length; i++) {
        String downloadUrl;
        if (kIsWeb) {
          downloadUrl = await uploadFileWeb(fileBytes[i], fileNames[i]);
        } else {
          downloadUrl = await uploadFileMobile(fileNames[i]);
        }
        fileUrls.add(downloadUrl);
      }

      await firestore.collection('request').add({
        'name': nameController.text,
        'ci': ciController.text,
        'phone': phoneController.text,
        'cell': cellPhonelController.text,
        'carrera': selectedCarrera,
        'evidence_urls': fileUrls,
        'evidence_names': fileNames,
        'estado': 'Pendiente',
        'fecha': selectedDate?.toIso8601String() ?? 'Fecha no seleccionada',
      });

      showAnimatedSnackBar(context, 'Solicitud Creada');
      clearFields();
    } catch (e) {
      print("Error al enviar solicitud: $e");
    }
  }

  Future<String> uploadFileWeb(Uint8List bytes, String fileName) async {
    final storageRef = storage.ref().child('evidences/$fileName');
    final metadata = SettableMetadata(contentType: _getMimeType(fileName));
    await storageRef.putData(bytes, metadata);
    return await storageRef.getDownloadURL();
  }

  Future<String> uploadFileMobile(String fileName) async {
    final storageRef = storage.ref().child('evidences/$fileName');
    await storageRef.putFile(selectedFile!);
    return await storageRef.getDownloadURL();
  }

  String _getMimeType(String fileName) {
    if (fileName.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    } else if (fileName.endsWith('.pdf')) {
      return 'application/pdf';
    } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.endsWith('.png')) {
      return 'image/png';
    } else {
      return 'application/octet-stream';
    }
  }

  void clearFields() {
    nameController.clear();
    ciController.clear();
    phoneController.clear();
    cellPhonelController.clear();
    setState(() {
      selectedFile = null;
      selectedBytes = null;
      selectedFileName = null;
      selectedCarrera = null;
      selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const Icon(
          Icons.arrow_back, 
          size: 25,
          color: Colors.white,
        ),
        title: const Text(
          'Crear Solicitud',
          style: TextStyle(
            fontSize: 30, 
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF950A67),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: nameController,
                      label: 'Nombre',
                      icon: const Icon(Icons.person, color: Color(0xFF950A67)),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: ciController,
                      label: 'Ci/Pasaporte',
                      icon: const Icon(Icons.badge, color: Color(0xFF950A67)),
                      inputFormatter: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: phoneController,
                      label: 'Teléfono',
                      icon: const Icon(Icons.phone, color: Color(0xFF950A67)),
                      inputFormatter: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: cellPhonelController,
                      label: 'Numero de Celular',
                      icon: const Icon(Icons.phone_android_outlined, color: Color(0xFF950A67)),
                      inputFormatter: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),
                    SimpleDatePickerFormField(
                      onDateSelected: (DateTime? date) {
                        setState(() {
                          selectedDate = date;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ComboBox(
                      itemsList: carreras,
                      hintText: 'Carrera',
                      selectedValue: selectedCarrera,
                      icon: const Icon(Icons.school, color: Color(0xFF950A67)),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCarrera = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF950A67),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: selectFile,
                      child: const Text('Adjuntar Evidencia'),
                    ),
                    const SizedBox(height: 10),
                    if (selectedFileName != null)
                      Text('Archivo seleccionado: $selectedFileName'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF950A67),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: addRequest,
                      child: const Text('Enviar Solicitud'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Icon icon,
    List<TextInputFormatter>? inputFormatter,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatter,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 18),
        prefixIcon: icon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF950A67)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF950A67)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF950A67)),
        ),
      ),
    );
  }
}
