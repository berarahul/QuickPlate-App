class TableReservation {
  final String id;
  final String userId;
  final String tableId;
  final List<int> seatNumbers;
  final String reservationDate;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double depositPaidAmount;
  final String depositStatus;
  final String reservationStatus;
  final String? qrCodeData;
  final DateTime createdAt;

  TableReservation({
    required this.id,
    required this.userId,
    required this.tableId,
    required this.seatNumbers,
    required this.reservationDate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.depositPaidAmount,
    required this.depositStatus,
    required this.reservationStatus,
    this.qrCodeData,
    required this.createdAt,
  });

  factory TableReservation.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    return TableReservation(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] : (json['userId'] ?? ''),
      tableId: json['tableId'] ?? '',
      seatNumbers: json['seatNumbers'] != null
          ? List<int>.from(json['seatNumbers'])
          : [],
      reservationDate: json['reservationDate'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
      depositPaidAmount: (json['depositPaidAmount'] as num?)?.toDouble() ?? 0.0,
      depositStatus: json['depositStatus'] ?? 'pending',
      reservationStatus: json['reservationStatus'] ?? 'booked',
      qrCodeData: json['qrCodeData'],
      createdAt: parseDate(json['createdAt']),
    );
  }
}
