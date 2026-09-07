import '../model/table_session_request.dart';
import '../model/table_session_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/api_endpoints.dart';

class TableOccupiedDetails {
  final int maxCapacity;
  final List<String> occupiedChairs;

  TableOccupiedDetails({
    required this.maxCapacity,
    required this.occupiedChairs,
  });
}

class LeaveTableSessionResult {
  final bool success;
  final String message;

  LeaveTableSessionResult({
    required this.success,
    required this.message,
  });
}

class ScanRepository {
  final ApiClient _apiClient;

  ScanRepository(this._apiClient);

  Future<TableSessionResponse> createTableSession(
    TableSessionRequest request,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.tableSession,
        data: request.toJson(),
      );

      return TableSessionResponse.fromJson(response.data);
    } on ApiException catch (_) {
      rethrow;
    } catch (e) {
      throw DefaultException(
        'An unexpected error occurred during table session creation',
      );
    }
  }

  Future<LeaveTableSessionResult> leaveTableSession() async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.leaveTableSession,
      );
      final success = response.data['success'] == true;
      final message = response.data['message']?.toString() ??
          (success
              ? 'Table session ended successfully.'
              : 'Failed to end table session.');
      return LeaveTableSessionResult(success: success, message: message);
    } on ApiException catch (e) {
      return LeaveTableSessionResult(success: false, message: e.message);
    } catch (e) {
      return LeaveTableSessionResult(
        success: false,
        message: 'An unexpected error occurred while ending table session',
      );
    }
  }

  Future<TableOccupiedDetails> getOccupiedChairsDetails(String tableId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.occupiedChairs(tableId),
      );
      if (response.data['success'] == true &&
          response.data['data'] != null) {
        final data = response.data['data'];
        final maxCap = (data['maxCapacity'] is int) ? data['maxCapacity'] as int : 4;
        final occupied = data['occupiedChairs'] != null
            ? List<String>.from(data['occupiedChairs'])
            : <String>[];
        return TableOccupiedDetails(
          maxCapacity: maxCap,
          occupiedChairs: occupied,
        );
      }
      return TableOccupiedDetails(maxCapacity: 4, occupiedChairs: []);
    } on ApiException catch (_) {
      return TableOccupiedDetails(maxCapacity: 4, occupiedChairs: []);
    } catch (e) {
      return TableOccupiedDetails(maxCapacity: 4, occupiedChairs: []);
    }
  }

  Future<List<String>> getOccupiedChairs(String tableId) async {
    final details = await getOccupiedChairsDetails(tableId);
    return details.occupiedChairs;
  }
}
