import '../models/auth_session.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  Future<AuthSession> login(String username, String password) async {
    final data = await _client.post('/auth/login', body: {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    return AuthSession.fromJson(data);
  }

  Future<Map<String, dynamic>> me() async =>
      await _client.get('/auth/me') as Map<String, dynamic>;
}
