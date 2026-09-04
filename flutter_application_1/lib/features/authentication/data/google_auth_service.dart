import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/auth_config.dart';

class GoogleAuthPayload {
  final String? idToken;
  final String? accessToken;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? googleSubjectId;

  GoogleAuthPayload({
    this.idToken,
    this.accessToken,
    required this.email,
    this.name,
    this.avatarUrl,
    this.googleSubjectId,
  });

  Map<String, dynamic> toJson() {
    return {
      'credential': idToken,
      'idToken': idToken,
      'accessToken': accessToken,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'googleSubjectId': googleSubjectId,
    };
  }
}

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AuthConfig.googleWebClientId : null,
    serverClientId: AuthConfig.googleServerClientId.isNotEmpty
        ? AuthConfig.googleServerClientId
        : null,
    scopes: <String>[
      'email',
      'profile',
      'openid',
    ],
  );

  /// Triggers standard real Google Sign-In flow across Mobile & Web
  Future<GoogleAuthPayload?> signIn() async {
    try {
      debugPrint('[GoogleAuthService] Starting Google Sign-In with clientId: ${kIsWeb ? AuthConfig.googleWebClientId : 'Native'}');
      
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('[GoogleAuthService] Google Sign-In was cancelled or closed by user');
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      debugPrint('[GoogleAuthService] Successfully authenticated Google account: ${account.email}');

      return GoogleAuthPayload(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
        email: account.email,
        name: account.displayName ?? account.email.split('@').first,
        avatarUrl: account.photoUrl,
        googleSubjectId: account.id,
      );
    } catch (e) {
      debugPrint('[GoogleAuthService] Error during Google Sign-In: $e');
      rethrow;
    }
  }

  /// Attempts silent sign in if user previously granted permissions
  Future<GoogleAuthPayload?> signInSilently() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;
      return GoogleAuthPayload(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
        email: account.email,
        name: account.displayName ?? account.email.split('@').first,
        avatarUrl: account.photoUrl,
        googleSubjectId: account.id,
      );
    } catch (e) {
      debugPrint('[GoogleAuthService] Silent sign-in skipped: $e');
      return null;
    }
  }

  /// Signs out from Google account
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] Error during Google Sign-Out: $e');
    }
  }

  /// Disconnects Google account
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('[GoogleAuthService] Error during Google disconnect: $e');
    }
  }
}
