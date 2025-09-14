import 'package:money_tracker_mobile/core/api_client.dart';
import 'package:money_tracker_mobile/models/stats.dart';

class StatsRepository {
  StatsRepository(this._api);
  final ApiClient _api;

  Future<Stats> fetch() async {
    final res = await _api.getJson('/stats');
    return Stats.fromJson(res as Map<String, dynamic>);
  }
}

