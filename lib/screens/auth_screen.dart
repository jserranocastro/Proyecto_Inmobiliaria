import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import '../widgets/property_card.dart';
import 'add_property_screen.dart';
import 'main_screen.dart';

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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  int _currentStep = 0;
  bool _registrationSuccess = false;

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

  Future<bool> _isUnique(String field, String value) async {
    final query = await _firestore
        .collection('users')
        .where(field, isEqualTo: value)
        .get();
    return query.docs.isEmpty;
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        _showError('Por favor, introduce tu nombre y apellidos');
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      final username = _usernameController.text.trim();
      if (username.isEmpty) {
        _showError('El nombre de usuario es obligatorio');
        return;
      }
      setState(() => _isLoading = true);
      bool unique = await _isUnique('username', username);
      setState(() => _isLoading = false);
      if (!unique) {
        _showError('El nombre de usuario ya está en uso');
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        _showError('Introduce un email válido');
        return;
      }
      if (password.length < 8) {
        _showError('La contraseña debe tener al menos 8 caracteres');
        return;
      }
      setState(() => _isLoading = true);
      bool unique = await _isUnique('email', email);
      setState(() => _isLoading = false);
      if (!unique) {
        _showError('El email ya está registrado');
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      final phone = _phoneController.text.trim();
      if (phone.length != 9 || int.tryParse(phone) == null) {
        _showError('El teléfono debe tener 9 dígitos');
        return;
      }
      setState(() => _isLoading = true);
      bool unique = await _isUnique('phone', phone);
      if (!unique) {
        setState(() => _isLoading = false);
        _showError('El número de teléfono ya está en uso');
        return;
      }
      await _register();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _register() async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      await userCredential.user!.updateDisplayName(_usernameController.text.trim());
      
      setState(() {
        _isLoading = false;
        _registrationSuccess = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showError(e.message ?? 'Error en el registro');
    }
  }

  Future<void> _login() async {
    final usernameOrEmail = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (usernameOrEmail.isEmpty || password.isEmpty) {
      _showError('Por favor, rellena todos los campos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String email = usernameOrEmail;

      // Si no parece un email (no contiene @), buscamos el email asociado al nombre de usuario en Firestore
      if (!usernameOrEmail.contains('@')) {
        final userQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          _showError('El nombre de usuario no existe');
          setState(() => _isLoading = false);
          return;
        }

        email = userQuery.docs.first.get('email');
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Error de autenticación');
    } catch (e) {
      _showError('Error inesperado al iniciar sesión');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isLogin ? 'Mi Cuenta' : 'Crear Cuenta'),
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ) 
            : null,
      ),
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData && (_isLogin || _registrationSuccess)) {
            if (_registrationSuccess) {
              return _buildWelcomeScreen();
            }
            return _buildProfileScreen(snapshot.data!);
          }
          
          return _isLogin ? _buildLoginView() : _buildRegisterView();
        },
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: const Icon(Icons.check_circle, size: 100, color: Colors.green),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Bienvenido!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu cuenta ha sido creada con éxito. ¿Qué quieres hacer ahora?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Publicar Anuncio'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Explorar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.home_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          const Text(
            '¡Bienvenido de nuevo!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Inicia sesión para gestionar tus inmuebles',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de usuario o Email',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entrar'),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _isLogin = false),
            child: const Text('¿No tienes cuenta? Regístrate aquí'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterView() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentStep + 1) / 4,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  _getStepTitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                _buildCurrentStepFields(),
                const SizedBox(height: 40),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            child: const Text('Volver'),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(_currentStep == 3 ? 'Finalizar' : 'Continuar'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (_currentStep == 0)
                  TextButton(
                    onPressed: () => setState(() => _isLogin = true),
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Dinos tu nombre';
      case 1: return 'Elige un nombre de usuario';
      case 2: return 'Correo y contraseña';
      case 3: return 'Tu número de contacto';
      default: return '';
    }
  }

  Widget _buildCurrentStepFields() {
    switch (_currentStep) {
      case 0:
        return Column(
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Apellidos', prefixIcon: Icon(Icons.person_outline)),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        );
      case 1:
        return TextField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: 'Nombre de usuario', prefixIcon: Icon(Icons.alternate_email)),
        );
      case 2:
        return Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
            ),
          ],
        );
      case 3:
        return TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Número de teléfono',
            prefixIcon: Icon(Icons.phone_outlined),
            hintText: 'Ej: 600123456',
          ),
          keyboardType: TextInputType.phone,
          maxLength: 9,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildProfileScreen(User user) {
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
                    onPressed: () {
                      _auth.signOut();
                      setState(() {
                        _registrationSuccess = false;
                        _isLogin = true;
                        _currentStep = 0;
                      });
                    },
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
}
