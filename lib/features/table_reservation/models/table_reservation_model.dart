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

  List<String> get chairIds => seatNumbers.map((n) => 'Chair $n').toList();
  int get seatsBooked => seatNumbers.length;

  bool get isSlotExpired {
    try {
      final now = DateTime.now();
      if (endTime.isEmpty) return false;

      final parsed = DateTime.tryParse(endTime);
      if (parsed != null) {
        return now.isAfter(parsed);
      }

      final parts = endTime.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        final endDt = DateTime(now.year, now.month, now.day, hour, minute);
        return now.isAfter(endDt);
      }
    } catch (_) {}
    return false;
  }

  bool get isActiveSlot {
    final st = reservationStatus.toLowerCase();
    final isValidStatus = (st == 'booked' || st == 'reserved' || st == 'checked_in');
    return isValidStatus && !isSlotExpired;
  }

  bool get isSlotActiveNow {
    if (reservationStatus.toLowerCase() == 'checked_in') return true;
    try {
      final now = DateTime.now();
      final resStart = DateTime.parse(startTime);
      final checkInAllowedFrom = resStart.subtract(const Duration(minutes: 10));
      return now.isAfter(checkInAllowedFrom) && !isSlotExpired;
    } catch (_) {}
    return false;
  }

  bool get isUpcomingSlot {
    if (reservationStatus.toLowerCase() == 'checked_in') return false;
    try {
      final now = DateTime.now();
      final resStart = DateTime.parse(startTime);
      final checkInAllowedFrom = resStart.subtract(const Duration(minutes: 10));
      return now.isBefore(checkInAllowedFrom);
    } catch (_) {}
    return true;
  }

  factory TableReservation.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      try {
        return DateTime.parse(date.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle seatsBooked (number) vs seatNumbers (List)
    List<int> parseSeats() {
      if (json['seatNumbers'] != null &&
          json['seatNumbers'] is List &&
          (json['seatNumbers'] as List).isNotEmpty) {
        return List<int>.from(
          (json['seatNumbers'] as List).map((x) => (x as num).toInt()),
        );
      }
      final count = (json['seatsBooked'] as num?)?.toInt() ?? 1;
      return List<int>.generate(count, (i) => i + 1);
    }

    // Handle deposit paid amount (backend uses totalDeposit / depositPaidAmount)
    final deposit = (json['depositPaidAmount'] as num?)?.toDouble() ??
        (json['totalDeposit'] as num?)?.toDouble() ??
        (json['depositRequired'] as num?)?.toDouble() ??
        0.0;

    // Handle status (backend uses status, frontend uses reservationStatus)
    final statusRaw = json['reservationStatus'] ?? json['status'] ?? 'booked';

    // Handle deposit status
    final depStatusRaw = json['depositStatus'] ??
        (json['paymentStatus']?.toString().toLowerCase() == 'paid'
            ? 'paid'
            : 'completed');

    final idVal = json['_id'] ?? json['id'] ?? '';

    return TableReservation(
      id: idVal,
      userId: json['userId'] is Map
          ? json['userId']['_id']
          : (json['userId'] ?? ''),
      tableId: json['tableId'] ?? '',
      seatNumbers: parseSeats(),
      reservationDate: json['reservationDate'] ?? json['startTime'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ??
          ((json['durationHours'] as num?)?.toDouble() != null
              ? ((json['durationHours'] as num).toDouble() * 60).toInt()
              : 60),
      depositPaidAmount: deposit,
      depositStatus: depStatusRaw,
      reservationStatus: statusRaw.toString().toLowerCase(),
      qrCodeData: json['qrCodeData'] ?? json['qrCode'] ?? idVal,
      createdAt: parseDate(json['createdAt']),
    );
  }
}
