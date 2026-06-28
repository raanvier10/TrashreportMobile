import '../../../core/api/api_client.dart';

class ArtikelService {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> fetchArtikel() async {
    try {
      final response = await _apiClient.dio.get('/artikel');
      if (response.statusCode == 200) {
        return response.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}