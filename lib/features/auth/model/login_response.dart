class LoginResponse {
  final bool success;
  final String message;
  final LoginData? data;

  LoginResponse({required this.success, required this.message, this.data});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final LoginUser? user;
  final String? token;

  LoginData({this.user, this.token});

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: json['user'] != null ? LoginUser.fromJson(json['user']) : null,
      token: json['token'],
    );
  }
}

class LoginUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isVerified;
  final String? idCardImage;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? lastLoginAt;

  LoginUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isVerified,
    this.idCardImage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      isVerified: json['isVerified'] ?? false,
      idCardImage: json['idCardImage'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      lastLoginAt: json['lastLoginAt'],
    );
  }
}
