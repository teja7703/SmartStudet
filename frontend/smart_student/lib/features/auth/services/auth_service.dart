import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    print("GOOGLE LOGIN START");

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    print("ACCOUNT SELECTED");

    if (googleUser == null) {
      print("USER CANCELLED");
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    print("TOKEN RECEIVED");

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    print("FIREBASE LOGIN");

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
