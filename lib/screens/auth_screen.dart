import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import '../widgets/property_card.dart';
import 'add_property_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _firebaseService = FirebaseService();
  final _locationService = LocationService();
  final _prefsService = PreferencesService();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  String? _defaultProvince;
  String? _defaultCity;

  @override
  void initState() {
    super.initState();
    _loadDefaultLocation();
  }

  Future<void> _loadDefaultLocation() async {
    final loc = await _prefsService.getDefaultLocation();
    setState(() {
      _defaultProvince = loc['province'];
      _defaultCity = loc['city'];
    });
  }

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

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 8 caracteres')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } else {
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

        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'createdAt': Timestamp.now(),
        });

        await userCredential.user!.updateDisplayName(username);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Error de autenticación')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLocationDialog() async {
    await _locationService.init();
    String? selectedProv = _defaultProvince;
    String? selectedCity = _defaultCity;
    List<String> provinces = _locationService.getProvinces();
    List<String> cities = selectedProv != null ? _locationService.getMunicipios(selectedProv) : [];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Definir ubicación por defecto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedProv,
                decoration: const InputDecoration(labelText: 'Provincia'),
                items: provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (val) {
                  setDialogState(() {
                    selectedProv = val;
                    selectedCity = null;
                    cities = _locationService.getMunicipios(val!);
                  });
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedCity,
                decoration: const InputDecoration(labelText: 'Municipio'),
                items: cities.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: selectedProv == null ? null : (val) => setDialogState(() => selectedCity = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selectedProv != null && selectedCity != null
                  ? () async {
                      await _prefsService.setDefaultLocation(selectedProv!, selectedCity!);
                      _loadDefaultLocation();
                      if (context.mounted) Navigator.pop(context);
                    }
                  : null,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isLogin ? 'Mi Cuenta' : 'Crear Cuenta'),
        surfaceTintColor: Colors.transparent,
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final user = snapshot.data!;
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                            child: const CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: Color(0xFF0052D4), size: 40),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? 'Usuario',
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                Text(user.email ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                            onPressed: () => _auth.signOut(),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on, color: Color(0xFF0052D4)),
                          title: const Text('Definir ubicación', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(_defaultCity != null ? '$_defaultCity, $_defaultProvince' : 'No definida'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _showLocationDialog,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Icon(Icons.home_work_rounded, color: Color(0xFF0052D4), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Mis Anuncios',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Property>>(
                    stream: _firebaseService.getPropertiesForUser(user.uid),
                    builder: (context, propertySnapshot) {
                      if (propertySnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final properties = propertySnapshot.data ?? [];
                      
                      if (properties.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.post_add, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('No has publicado anuncios', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: properties.length,
                        itemBuilder: (context, index) {
                          final property = properties[index];
                          return Stack(
                            children: [
                              PropertyCard(
                                property: property,
                                onTap: () {},
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Row(
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.edit,
                                      color: Colors.blue,
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddPropertyScreen(propertyToEdit: property),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      icon: Icons.delete,
                                      color: Colors.red,
                                      onPressed: () => _confirmDelete(context, property.id),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.home_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? '¡Bienvenido de nuevo!' : 'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Inicia sesión para gestionar tus inmuebles' : 'Únete a nuestra comunidad',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                if (!_isLogin) ...[
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_isLogin ? 'Entrar' : 'Registrarse'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
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

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: IconButton(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String propertyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar anuncio?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firebaseService.deleteProperty(propertyId);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
