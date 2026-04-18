
import '../model/table_session_request.dart';
import '../model/table_session_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/api_endpoints.dart';

class ScanRepository {
  final ApiClient _apiClient;

  ScanRepository(this._apiClient);

  Future<TableSessionResponse> createTableSession(TableSessionRequest request) async {
    try {
      final response = await _apiClient.post(ApiEndpoints.tableSession, data: request.toJson());

      return TableSessionResponse.fromJson(response.data);
    } on ApiException catch (_) {
      rethrow;
    } catch (e) {
      throw DefaultException('An unexpected error occurred during table session creation');
    }
  }
}
