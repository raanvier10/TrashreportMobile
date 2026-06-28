import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import 'package:dio/dio.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('user_name', data['user']['name'] ?? '');
        await prefs.setString('user_email', data['user']['email'] ?? '');
        if (data['user']['foto_profil'] != null) {
          await prefs.setString('user_foto', data['user']['foto_profil']);
        }

        return {
          'success': true,
          'role': data['role'],
        };
      }
      return {'success': false, 'message': 'Gagal login'};
    } on DioException catch (e) {
      String message = 'Jaringan bermasalah';
      if (e.response != null) {
        message = e.response?.data['message'] ?? 'Login Gagal';
      }
      return {'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String phone, String password) async {
    try {
      final response = await _apiClient.dio.post('/register', data: {
        'nama': name,
        'email': email,
        'telepon': phone,
        'password': password,
      });

      if (response.statusCode == 201) {
        final data = response.data['data'];
        
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', data['role']);
        await prefs.setString('user_name', data['user']['name'] ?? '');
        await prefs.setString('user_email', data['user']['email'] ?? '');
        if (data['user']['foto_profil'] != null) {
          await prefs.setString('user_foto', data['user']['foto_profil']);
        }

        return {
          'success': true,
          'role': data['role'],
        };
      }
      return {'success': false, 'message': 'Gagal mendaftar'};
    } on DioException catch (e) {
      String message = 'Jaringan bermasalah';
      if (e.response != null) {
        if (e.response?.data['errors'] != null) {
          final errors = e.response?.data['errors'] as Map<String, dynamic>;
          message = errors.values.first[0];
        } else {
          message = e.response?.data['message'] ?? 'Pendaftaran Gagal';
        }
      }
      return {'success': false, 'message': message};
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/logout');
    } catch (e) {
      // Abaikan error jaringan saat logout
    } finally {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }
}