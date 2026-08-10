import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});
