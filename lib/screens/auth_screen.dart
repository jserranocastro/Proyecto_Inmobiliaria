import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && username.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
        // 1. Verificar si el nombre de usuario ya existe
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          throw FirebaseAuthException(
            code: 'username-already-in-use',
            message: 'El nombre de usuario ya está en uso.',
          );
        }

        // 2. Crear usuario en Auth
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // 3. Guardar datos adicionales en Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'createdAt': Timestamp.now(),
        });

        // 4. Actualizar el displayName para uso rápido
        await userCredential.user!.updateDisplayName(username);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error de autenticación')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Iniciar Sesión' : 'Crear Cuenta')),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle, size: 80, color: Colors.blueAccent),
                  const SizedBox(height: 10),
                  // Usamos displayName que hemos guardado al registrar
                  Text(
                    'Bienvenido, ${snapshot.data!.displayName ?? 'Usuario'}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text('${snapshot.data!.email}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _auth.signOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50]),
                  ),
                ],
              ),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (!_isLogin) ...[
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                      child: Text(_isLogin ? 'Entrar' : 'Registrarse'),
                    ),
                  ),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                  }),
                  child: Text(_isLogin
                      ? '¿No tienes cuenta? Regístrate aquí'
                      : '¿Ya tienes cuenta? Inicia sesión'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
