import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// Handles doctor photo uploads via ImageKit.
///
/// Flow:
/// 1. Fetch auth credentials (`token`, `signature`, `expire`) from the backend
///    endpoint `/api/imagekit/auth` (admin-only).
/// 2. POST the image directly to ImageKit's upload API using the auth params.
/// 3. Return the public CDN URL of the uploaded image.
class ImageKitService {
  final ApiClient _client;

  /// Your ImageKit public key — safe to embed in the client.
  /// This is NOT a secret; it is only used to identify your account during
  /// client-side uploads. The private key stays on the server.
  static const String _publicKey = 'your_imagekit_public_key';

  static const String _uploadUrl =
      'https://upload.imagekit.io/api/v1/files/upload';

  ImageKitService(this._client);

  /// Fetch one-time upload auth params from the backend.
  Future<Map<String, dynamic>> _getAuthParams() async {
    final data =
        await _client.get('/imagekit/auth') as Map<String, dynamic>;
    return data;
  }

  /// Upload [file] to ImageKit under `/doctors/` and return the public URL.
  ///
  /// Throws on network or server errors — callers should catch and display a
  /// user-friendly message.
  Future<String> uploadDoctorPhoto(File file) async {
    // 1. Get auth params from our backend.
    final auth = await _getAuthParams();

    // 2. Build the multipart upload request to ImageKit.
    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

    request.fields['publicKey'] = _publicKey;
    request.fields['signature'] = auth['signature'] as String;
    request.fields['token'] = auth['token'] as String;
    request.fields['expire'] = auth['expire'].toString();
    request.fields['fileName'] =
        'doctor_${DateTime.now().millisecondsSinceEpoch}.jpg';
    request.fields['folder'] = '/doctors';

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    // 3. Send and parse.
    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode != 200) {
      throw Exception(
          'ImageKit upload failed (${streamedResponse.statusCode}): $responseBody');
    }

    final json = jsonDecode(responseBody) as Map<String, dynamic>;
    return json['url'] as String;
  }
}
