/// The authenticated reception session returned by POST /auth/login.
class AuthSession {
  final String token;
  final String role; // 'reception' | 'admin'
  final String displayName;
  final String userId;

  const AuthSession({
    required this.token,
    required this.role,
    required this.displayName,
    required this.userId,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: (json['token'] ?? '') as String,
        role: (json['role'] ?? '') as String,
        displayName: (json['displayName'] ?? '') as String,
        userId: (json['userId'] ?? '') as String,
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'role': role,
        'displayName': displayName,
        'userId': userId,
      };
}
