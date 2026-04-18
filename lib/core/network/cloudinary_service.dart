import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class CloudinaryService {
  static const String cloudName = 'dt7ycd3xc';
  static const String apiKey = '859836134263289';
  static const String apiSecret = 'uBF83eMfcbwbmK75ZVKeGCQATO8';
  static const String uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      
      // Generate signature: sha1(timestamp=123456789<api_secret>)
      final paramsToSign = 'timestamp=$timestamp$apiSecret';
      final bytes = utf8.encode(paramsToSign);
      final digest = sha1.convert(bytes);
      final signature = digest.toString();

      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
        'api_key': apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      final response = await dio.post(uploadUrl, data: formData);
      
      if (response.statusCode == 200) {
        return response.data['secure_url']; // This is the web url (https://...)
      }
      return null;
    } catch (e) {
      print('Cloudinary Upload Error: $e');
      return null;
    }
  }
}
