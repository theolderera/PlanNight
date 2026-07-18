import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../api/api_client.dart';
import '../models/stats.dart';

/// Reads progress statistics from the API. Stats are computed server-side (and
/// change as tasks are checked off), so these are online reads; screens show a
/// friendly message if offline.
class StatsRepository {
  StatsRepository(this._client);

  final ApiClient _client;

  Future<DayStat> daily(String date) async {
    final res = await _client.dio.get('/stats/daily', queryParameters: {'date': date});
    return DayStat.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SummaryStat> summary({required String from, required String to}) async {
    final res = await _client.dio
        .get('/stats/summary', queryParameters: {'from': from, 'to': to});
    return SummaryStat.fromJson(res.data as Map<String, dynamic>);
  }

  Future<StreakStat> streak() async {
    final res = await _client.dio.get('/stats/streak');
    return StreakStat.fromJson(res.data as Map<String, dynamic>);
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(apiClientProvider));
});
