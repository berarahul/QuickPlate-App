import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../model/student_registration_request.dart';
import '../model/student_registration_response.dart';
import '../model/login_request.dart';
import '../model/login_response.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<StudentRegistrationResponse> registerStudent(
    StudentRegistrationRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: request.toJson(),
    );

    return StudentRegistrationResponse.fromJson(response.data);
  }

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      data: request.toJson(),
    );

    return LoginResponse.fromJson(response.data);
  }
}
