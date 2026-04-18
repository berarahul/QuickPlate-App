class StudentRegistrationRequest {
  final String name;
  final String email;
  final String password;
  final String role;
  final String idCardImage;

  StudentRegistrationRequest({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'student',
    required this.idCardImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'idCardImage': idCardImage,
    };
  }
}
