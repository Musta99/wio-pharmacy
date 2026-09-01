class DailyOperationalCheck {
  final String date; // yyyy-MM-dd
  final String type; // 'Morning' | 'Evening'
  final double? fridgeTemp;
  final double? roomTemp;
  final bool nearExpiryChecked;
  final bool reconciliationDone;
  final String completedBy;

  DailyOperationalCheck({
    required this.date,
    required this.type,
    this.fridgeTemp,
    this.roomTemp,
    required this.nearExpiryChecked,
    required this.reconciliationDone,
    required this.completedBy,
  });
}
