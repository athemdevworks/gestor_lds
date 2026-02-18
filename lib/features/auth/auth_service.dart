import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gestor_lds/features/auth/models/user_model.dart';
import 'package:gestor_lds/features/members/models/member_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- 1. STREAM DE AUTENTICACIÓN ---
  Stream<User?> get userStream => _auth.authStateChanges();

  // --- 2. STREAM DE DATOS DEL USUARIO ---
  Stream<UserModel?> getUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // --- 3. INICIAR SESIÓN (BLINDADO 🛡️) ---
  // Ahora busca en 'usernames' usando .doc().get() para cumplir la regla de seguridad
  Future<User?> signInWithEmailAndPassword(String identifier, String password) async {
    try {
      String emailToUse = identifier.trim();
      String cleanUsername = identifier.trim().toLowerCase(); // Normalizamos a minúsculas

      // PASO 1: DETECTAR SI ES UN NOMBRE DE USUARIO (No tiene @)
      if (!emailToUse.contains('@')) {

        // --- CAMBIO DE SEGURIDAD ---
        // En lugar de buscar en 'users' (que requiere permisos de lista),
        // vamos directo al documento en la colección pública 'usernames'.
        final docRef = await _db.collection('usernames').doc(cleanUsername).get();

        // Si el documento no existe, el usuario no es válido
        if (!docRef.exists) {
          throw 'El nombre de usuario no existe.';
        }

        // Si existe, recuperamos el email seguro
        emailToUse = docRef.data()?['email'];
      }

      // PASO 2: AUTENTICAR CON FIREBASE (Usando el correo real)
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: emailToUse,
          password: password
      );

      // PASO 3: VERIFICACIÓN DE INHABILITACIÓN
      if (result.user != null) {
        final userDoc = await _db.collection('users').doc(result.user!.uid).get();
        if (userDoc.exists) {
          final isActive = userDoc.data()?['isActive'] ?? true;

          if (!isActive) {
            await _auth.signOut();
            throw 'Esta cuenta ha sido inhabilitada por el administrador.';
          }
        }
      }

      return result.user;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') throw 'Credenciales incorrectas.';
      if (e.code == 'wrong-password') throw 'Contraseña incorrecta.';
      if (e.code == 'too-many-requests') throw 'Cuenta bloqueada temporalmente.';
      throw e.message ?? 'Error de autenticación.';
    } catch (e) {
      throw e.toString();
    }
  }

  // --- 4. REGISTRO ESTÁNDAR (Dual-Write) ---
  Future<User?> registerUser({
    required String email,
    required String password,
    required String username,
    required String nombres,
    required String apellidos,
    required String calling,
    required String organization,
    required UserRole role,
    String? phoneNumber,
    DateTime? birthDate,
    String? memberId,
  }) async {
    try {
      // 1. Crear en Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // Normalizamos el username
        final cleanUsername = username.trim().toLowerCase();

        final newUser = UserModel(
          uid: user.uid,
          email: email,
          username: cleanUsername,
          nombres: nombres,
          apellidos: apellidos,
          calling: calling,
          organization: organization,
          role: role,
          isApproved: false,
          isActive: true,
          memberId: memberId,
          phoneNumber: phoneNumber,
          birthDate: birthDate,
        );

        // 2. Guardar perfil completo en 'users' (Privado)
        await _db.collection('users').doc(user.uid).set(newUser.toMap());

        // 3. --- NUEVO: Guardar referencia en 'usernames' (Público/Lookup) ---
        await _db.collection('usernames').doc(cleanUsername).set({
          'email': email,
          'uid': user.uid,
        });

        // 4. Vincular Miembro (si aplica)
        if (memberId != null) {
          await _db.collection('members').doc(memberId).update({
            'relatedUserId': user.uid,
            'email': email,
          });
        }

        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar usuario: $e';
    }
    return null;
  }

  // --- 5. CREAR USUARIO PARA UN MIEMBRO (Dual-Write) ---
  Future<void> createAccountForMember({
    required MemberModel member,
    required String email,
    required String password,
    required UserRole role,
    required String username,
  }) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(
        name: 'TemporaryRegisterApp',
        options: Firebase.app().options,
      );

      UserCredential result = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      final String newUid = result.user!.uid;
      final cleanUsername = username.trim().toLowerCase();

      // 1. Crear el modelo
      final newUser = UserModel(
        uid: newUid,
        email: email,
        username: cleanUsername,
        nombres: member.firstName,
        apellidos: member.lastName,
        calling: member.calling ?? 'Sin Llamamiento',
        organization: member.servingOrganization ?? member.primaryOrganization,
        role: role,
        isApproved: true,
        isActive: true,
        memberId: member.id,
        phoneNumber: member.phone,
        birthDate: member.birthDate,
      );

      // 2. Guardar en 'users'
      await _db.collection('users').doc(newUid).set(newUser.toMap());

      // 3. --- NUEVO: Guardar en 'usernames' ---
      await _db.collection('usernames').doc(cleanUsername).set({
        'email': email,
        'uid': newUid,
      });

      // 4. Vincular
      await _db.collection('members').doc(member.id).update({
        'relatedUserId': newUid,
        'email': email,
      });

      await tempApp.delete();

    } catch (e) {
      if (tempApp != null) await tempApp.delete();
      throw 'Error al crear usuario para miembro: $e';
    }
  }

  // --- 6. CONTROL DE ACCESO ---
  Future<void> toggleUserAccess(String uid, bool isActive) async {
    await _db.collection('users').doc(uid).update({
      'isActive': isActive,
    });
  }

  // --- 7. UTILS Y RECUPERACIÓN ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ESTA FUNCIÓN YA NO SE DEBERÍA USAR EN EL LOGIN, PERO LA DEJAMOS POR SI ACASO
  // (Ahora el login usa la colección 'usernames' directo)
  Future<String?> getEmailFromUsername(String username) async {
    try {
      final doc = await _db.collection('usernames').doc(username.trim().toLowerCase()).get();
      if (doc.exists) return doc.data()?['email'];
      return null;
    } catch (e) { return null; }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use': return 'Este correo ya está registrado.';
      case 'weak-password': return 'La contraseña es muy débil.';
      case 'user-disabled': return 'Usuario inhabilitado.';
      case 'user-not-found': return 'Usuario no encontrado.';
      case 'wrong-password': return 'Contraseña incorrecta.';
      default: return 'Error: ${e.message}';
    }
  }
}