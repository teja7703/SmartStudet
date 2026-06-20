import 'package:dio/dio.dart';

import '../models/study_material_model.dart';

class StudyMaterialService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://smartstudent-api.onrender.com',
    ),
  );

  Future<List<StudyMaterialModel>> getStudyMaterials({
    required String academicLevel,
    required String subject,
  }) async {
    try {
      final response = await _dio.get(
        '/study-materials',
        queryParameters: {
          'academicLevel': academicLevel,
          'subject': subject,
        },
      );

      final List data =
          response.data['data'] ?? [];

      return data
          .map(
            (item) =>
                StudyMaterialModel.fromJson(
              item,
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}