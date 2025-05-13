import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:taller_1/auth/providers/usuarios_provider.dart';
import 'package:taller_1/widgets/input_decoration.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; //tamaño de la pantalla

    return Scaffold(
      //resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Stack(
          children: [cajaAzul(size), iconperson(), login(context)],
        ),
      ),
    );
  }

  Widget login(BuildContext context) {
    final usuarioProvider = Provider.of<UsuarioProvider>(context);
    
    return Column(
      children: [
        const SizedBox(height: 280),
        Container(
          padding: const EdgeInsets.all(
              20), //espacio entre el contenedor y el texto (los 4 lados)
          margin: const EdgeInsets.symmetric(horizontal: 40),
          width: double.infinity,
          //height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text('Bienvenido',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 30),
              Container(
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(children: [
                    TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecorations.inputDecoration(
                          hintext: 'ejemplo@gmail.com',
                          labelText: 'Correo Electronico',
                          icon: const Icon(Icons.alternate_email_rounded)),
                      validator: (value) {
                        String pattern =
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
                        RegExp regExp = RegExp(pattern);
                        return regExp.hasMatch(value!)
                            ? null
                            : 'El correo no es correcto';
                      },
                      onChanged: (value) => email = value,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      autocorrect: false,
                      obscureText: true,
                      decoration: InputDecorations.inputDecoration(
                          hintext: '********',
                          labelText: 'Contraseña',
                          icon: const Icon(Icons.lock_rounded)),
                      validator: (value) {
                        return (value != null && value.length >= 6)
                            ? null
                            : 'La contraseña debe ser de 6 caracteres';
                      },
                      onChanged: (value) => password = value,
                    ),
                    const SizedBox(height: 30),
                    MaterialButton(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        disabledColor: Colors.grey,
                        color: const Color.fromARGB(255, 20, 18, 110),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 80, vertical: 15),
                          child: const Text('Ingresar',
                              style: TextStyle(color: Colors.white)),
                        ),
                        onPressed: () async {
                          // Validamos el formulario
                          if (!formKey.currentState!.validate()) return;
    
                          // Llamamos al provider para hacer login
                          bool success =
                              await usuarioProvider.login(email, password);
                              print('email: $email');
                              print('password: $password');
    
                          if (success) {
                            Navigator.pushReplacementNamed(context, 'home');
                          } else {
                            // Mostrar un mensaje de error si falla
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Error'),
                                content: const Text(
                                    'No se pudo iniciar sesión. Verifica tus credenciales.'),
                                actions: [
                                  TextButton(
                                    child: const Text('OK'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  )
                                ],
                              ),
                            );
                          }
                          
                        }),
                  ]),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 50),
        const Text(
          '¿No tienes cuenta?',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  SafeArea iconperson() {
    return SafeArea(
      //asegura que se adapte a cualquier celular
      child: Container(
        margin: const EdgeInsets.only(top: 30),
        width: double.infinity,
        child: const Icon(Icons.person_pin, color: Colors.white, size: 100),
      ),
    );
  }

  Container cajaAzul(Size size) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
        Color.fromARGB(255, 20, 18, 110),
        Color.fromARGB(255, 22, 16, 190),
      ])),
      width: double.infinity,
      height: size.height * 0.4,
      /*child: Stack(
        children: [
          Positioned(
            top: 90,
            left: 30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: const Color.fromRGBO(255, 255, 255, 0.05),
              ),
            ),
          ),
        ],
      ),*/
    );
  }
}
