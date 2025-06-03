import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taller_1/Services/socket_service.dart';
import 'package:taller_1/auth/auth.dart';
import 'package:taller_1/auth/providers/audios_provider.dart';
import 'package:taller_1/auth/providers/diagnosticos_provider.dart';
import 'package:taller_1/pages/audios.dart';
import 'package:taller_1/pages/diagnosticos.dart';
//import 'package:taller_1/pages/home.dart';
import 'package:taller_1/pages/login.dart';

class MyApp extends StatelessWidget {
  final SocketService socketService;

  // Hacemos un constructor que reciba el SocketService
  const MyApp({Key? key, required this.socketService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider(socketService)),
        ChangeNotifierProvider(create: (_) => DiagnosticosProvider(socketService)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Material App',
        routes: {
          'login': (_) => const Login(),
          //'home': (_) => const Home(),
          'diagnosticos': (_) => Diagnosticos(),
          'audios': (_) => const Audios(),
        },
        initialRoute: 'login',
      ),
    );
  }
}

void main() {
  final socketService = SocketService();
  runApp(
    MyApp(socketService: socketService),
  );
}