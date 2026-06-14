import 'package:dio/dio.dart';

class AuthApiService {
  final Dio dio = Dio();

  Future<void> login({
    required String firebaseUid,
    required String email,
    required String name,
    required String photoUrl,
  }) async {
    await dio.post(
      'http://10.0.2.2:3000/api/auth/login',
      data: {
        'firebaseUid': firebaseUid,
        'email': email,
        'name': name,
        'photoUrl': photoUrl,
      },
    );
  }
}