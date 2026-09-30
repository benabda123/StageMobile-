import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/leave_analysis_model.dart';
import '../domain/meeting_plan_model.dart';

final Provider<AiAssistantRepository> aiAssistantRepositoryProvider =
    Provider<AiAssistantRepository>(
  (Ref<AiAssistantRepository> ref) => AiAssistantRepository(ref.watch(dioProvider)),
);

class AiAssistantRepository {
  AiAssistantRepository(this._dio);

  final Dio _dio;

  Future<MeetingPlan> generateMeetingPlan({
    required String objective,
    int? departmentId,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'objective': objective,
      };
      if (departmentId != null) {
        body['departmentId'] = departmentId;
      }
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/ai/meeting-plan',
        data: body,
        options: Options(
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        return MeetingPlan.fromJson(data);
      }
      throw Exception('Format de réponse inattendu.');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  String _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Serveur injoignable. Vérifiez la connexion et réessayez.';
    }
    final int? status = error.response?.statusCode;
    final dynamic body = error.response?.data;
    if (body is Map<String, dynamic>) {
      return (body['error'] as String?) ??
          (body['message'] as String?) ??
          'Erreur serveur ($status).';
    }
    return 'Erreur inattendue. Réessayez.';
  }

  Future<LeaveAnalysis> analyzeLeave({required int leaveRequestId}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/ai/leave-analysis',
        data: <String, dynamic>{'leaveRequestId': leaveRequestId},
        options: Options(
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );
      final dynamic data = response.data;
      if (data is Map<String, dynamic>) {
        return LeaveAnalysis.fromJson(data);
      }
      throw Exception('Format de réponse inattendu.');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }
}
