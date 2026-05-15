 import 'package:flutter/material.dart';
 import '../database/user_database.dart';

 class RegisterScreen extends StatefulWidget {
   const RegisterScreen({super.key});

   @override
   State<RegisterScreen> createState() => _RegisterScreenState();
 }

 class _RegisterScreenState extends State<RegisterScreen> {
   final nameController = TextEditingController();
   final emailController = TextEditingController();
   final passwordController = TextEditingController();

   Future register() async {
     await UserDatabase.instance.insertUser({
       'name': nameController.text,
       'email': emailController.text,
       'password': passwordController.text,
     });

     Navigator.pop(context);
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(title: const Text('Crear cuenta')),
       body: Padding(
         padding: const EdgeInsets.all(20),
         child: Column(
           children: [
             TextField(
               controller: nameController,
               decoration: const InputDecoration(
                 labelText: 'Nombre',
               ),
             ),

             TextField(
               controller: emailController,
               decoration: const InputDecoration(
                 labelText: 'Correo',
               ),
             ),

             TextField(
               controller: passwordController,
               obscureText: true,
               decoration: const InputDecoration(
                 labelText: 'Contraseña',
               ),
             ),

             const SizedBox(height: 20),

             ElevatedButton(
               onPressed: register,
               child: const Text('Registrarse'),
             ),
           ],
         ),
       ),
     );
   }
 }