import 'package:equatable/equatable.dart';

class AdminDashboardStats extends Equatable {
  final int totalUsers;
  final int activeUsers;
  final int disabledUsers;
  final int suspendedUsers;
  final int bannedUsers;
  final int verifiedUsers;
  final int openReports;
  final int reportsInReview;
  final int closedReports;
  final Map<String, int> extras;

  const AdminDashboardStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.disabledUsers = 0,
    this.suspendedUsers = 0,
    this.bannedUsers = 0,
    this.verifiedUsers = 0,
    this.openReports = 0,
    this.reportsInReview = 0,
    this.closedReports = 0,
    this.extras = const {},
  });

  @override
  List<Object?> get props => [
        totalUsers,
        activeUsers,
        disabledUsers,
        suspendedUsers,
        bannedUsers,
        verifiedUsers,
        openReports,
        reportsInReview,
        closedReports,
        extras,
      ];
}
