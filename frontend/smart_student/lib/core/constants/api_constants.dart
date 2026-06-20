import 'dart:io';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'https://smartstudent-api.onrender.com';
    }
    return 'https://smartstudent-api.onrender.com';
  }

  static String get authLogin => '$baseUrl/api/auth/login';
  static String get dashboard => '$baseUrl/api/dashboard';
  static String get studyMaterials => '$baseUrl/api/study-materials';
  static String get previousPapers => '$baseUrl/api/previous-papers';
  static String get careers => '$baseUrl/api/careers';
  static String get stories => '$baseUrl/api/stories';
  static String get quizzes => '$baseUrl/api/quizzes';
}
