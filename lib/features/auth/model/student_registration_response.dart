class StudentRegistrationResponse {
  final bool success;
  final String message;
  final Data? data;

  StudentRegistrationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory StudentRegistrationResponse.fromJson(Map<String, dynamic> json) {
    return StudentRegistrationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }
}

class Data {
  final User? user;
  final String? token;
  final bool requiresVerification;

  Data({
    this.user,
    this.token,
    required this.requiresVerification,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      token: json['token'],
      requiresVerification: json['requiresVerification'] ?? false,
    );
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isVerified;
  final String? idCardImage;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
    this.idCardImage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isVerified: json['isVerified'] ?? false,
      idCardImage: json['idCardImage'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}
