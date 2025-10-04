import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/models/spending_prediction.dart';

class AnalysisRepository {
  AnalysisRepository(this._api);
  final ApiClient _api;

  Future<SpendingPrediction> fetchSpendingPrediction(
      {required int year, required int month}) async {
    final res = await _api.getJson(
      '/analytics/spending-prediction',
      query: {
        'year': year.toString(),
        'month': month.toString(),
      },
    );
    return SpendingPrediction.fromJson(res as Map<String, dynamic>);
  }
}
