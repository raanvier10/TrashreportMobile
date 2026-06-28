import '../../../core/api/api_client.dart';

class TugasService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> fetchTugas() async {
    try {
      final response = await _apiClient.dio.get('/petugas/tugas');
      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}