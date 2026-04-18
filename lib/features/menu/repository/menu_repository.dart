import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/menu_response.dart';

class MenuRepository {
  final ApiClient _apiClient;

  MenuRepository(this._apiClient);

  Future<MenuResponse> getMenu() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.studentMenu);
      return MenuResponse.fromJson(response.data);
    } on ApiException catch (_) {
      rethrow;
    } catch (e) {
      throw DefaultException('An unexpected error occurred while fetching the menu');
    }
  }
}
