import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taller_1/auth/providers/usuarios_provider.dart';
import 'package:taller_1/pages/home.dart';
import 'package:taller_1/pages/login.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Material App',
        routes: {
          'login': (_) => const Login(),
          'home': (_) => const Home(),
        },
        initialRoute: 'login',
      ),
    );
  }
}