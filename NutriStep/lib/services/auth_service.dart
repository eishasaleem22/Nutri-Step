// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Trigger Google Sign-In flow
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw 'Sign in aborted';
    // Obtain auth details
    final GoogleSignInAuthentication googleAuth =
    await googleUser.authentication;
    // Create credential for Firebase
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    // Sign in to Firebase with credential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
