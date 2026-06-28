import '../../../core/api/api_client.dart';

class LaporanService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> fetchLaporan() async {
    try {
      final response = await _apiClient.dio.get('/pelapor/laporan');
      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchLaporanPublik() async {
    try {
      final response = await _apiClient.dio.get('/pelapor/laporan/publik');
      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}