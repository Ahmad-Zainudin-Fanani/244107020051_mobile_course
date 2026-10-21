class AuthSession {
  const AuthSession({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

class AuthRepository {
  // Titik integrasi dengan FirebaseAuth.instance.signInWithEmailAndPassword
  // atau OAuth/Google Sign-In saat backend siap.
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Email atau kata sandi tidak valid (min 6 karakter)');
    }

    // Simulasi JWT token
    final now = DateTime.now().millisecondsSinceEpoch;
    return AuthSession(
      access: 'mock-access-for-$email-$now',
      refresh: 'mock-refresh-for-$email-$now',
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (refreshToken.isEmpty || refreshToken == 'expired') {
      throw Exception('Refresh token tidak valid atau telah kedaluwarsa');
    }
    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
