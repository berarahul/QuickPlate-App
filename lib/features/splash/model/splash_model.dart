class SplashModel {
  final bool hasUpdate;
  final bool isAuthenticated;

  SplashModel({
    required this.hasUpdate,
    required this.isAuthenticated,
  });

  factory SplashModel.fromJson(Map<String, dynamic> json) {
    return SplashModel(
      hasUpdate: json['hasUpdate'] ?? false,
      isAuthenticated: json['isAuthenticated'] ?? false,
    );
  }
}
