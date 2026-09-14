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

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.resetPassword,
      data: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phoneNumber,
    String? idCardImage,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (idCardImage != null) data['idCardImage'] = idCardImage;

    final response = await _apiClient.patch(
      ApiEndpoints.profile,
      data: data,
    );
    return response.data;
  }
}
