class CostBreakdown {
  final double ratePerChair;
  final int seatCount;
  final double baseCost;
  final double durationMultiplier;
  final double finalDepositCost;

  CostBreakdown({
    required this.ratePerChair,
    required this.seatCount,
    required this.baseCost,
    required this.durationMultiplier,
    required this.finalDepositCost,
  });

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    return CostBreakdown(
      ratePerChair: (json['ratePerChair'] as num?)?.toDouble() ?? 0.0,
      seatCount: (json['seatCount'] as num?)?.toInt() ?? 0,
      baseCost: (json['baseCost'] as num?)?.toDouble() ?? 0.0,
      durationMultiplier: (json['durationMultiplier'] as num?)?.toDouble() ?? 1.0,
      finalDepositCost: (json['finalDepositCost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AvailableTable {
  final String id;
  final String tableId;
  final int maxCapacity;
  final List<int> reservedSeatNumbers;
  final List<int> sessionRunningSeatNumbers;
  final List<int> availableSeats;
  final CostBreakdown? costBreakdown;

  AvailableTable({
    required this.id,
    required this.tableId,
    required this.maxCapacity,
    required this.reservedSeatNumbers,
    required this.sessionRunningSeatNumbers,
    required this.availableSeats,
    this.costBreakdown,
  });

  factory AvailableTable.fromJson(Map<String, dynamic> json) {
    final capacity = (json['totalSeats'] as num?)?.toInt() ?? (json['maxCapacity'] as num?)?.toInt() ?? 4;
    final occupiedCount = (json['occupiedSeats'] as num?)?.toInt() ?? 0;

    List<int> reservedSeats = [];
    if (json['reservedSeatNumbers'] != null) {
      reservedSeats = List<int>.from(json['reservedSeatNumbers']);
    }

    List<int> sessionRunningSeats = [];
    if (json['sessionRunningSeatNumbers'] != null) {
      sessionRunningSeats = List<int>.from(json['sessionRunningSeatNumbers']);
    }

    if (json['reservedSeatNumbers'] == null && json['sessionRunningSeatNumbers'] == null) {
      for (int i = 1; i <= occupiedCount; i++) {
        reservedSeats.add(i);
      }
    }

    List<int> availSeats = [];
    if (json['availableSeatNumbers'] is List) {
      availSeats = List<int>.from(json['availableSeatNumbers']);
    } else if (json['availableSeats'] is List) {
      availSeats = List<int>.from(json['availableSeats']);
    } else {
      for (int i = 1; i <= capacity; i++) {
        if (!reservedSeats.contains(i) && !sessionRunningSeats.contains(i)) {
          availSeats.add(i);
        }
      }
    }

    final rate = (json['perChairRate'] as num?)?.toDouble() ?? 50.0;
    final deposit = (json['depositRequired'] as num?)?.toDouble() ?? rate;

    final breakdown = json['costBreakdown'] != null
        ? CostBreakdown.fromJson(json['costBreakdown'])
        : CostBreakdown(
            ratePerChair: rate,
            seatCount: 1,
            baseCost: rate,
            durationMultiplier: rate > 0 ? (rate / 50.0) : 1.0,
            finalDepositCost: deposit,
          );

    return AvailableTable(
      id: json['_id'] ?? json['id'] ?? json['tableId'] ?? '',
      tableId: json['tableId'] ?? '',
      maxCapacity: capacity,
      reservedSeatNumbers: reservedSeats,
      sessionRunningSeatNumbers: sessionRunningSeats,
      availableSeats: availSeats,
      costBreakdown: breakdown,
    );
  }
}

class TableAvailabilityResponse {
  final String date;
  final String timeSlot;
  final int durationMinutes;
  final bool isCanteenOpen;
  final String openingTime;
  final String closingTime;
  final List<AvailableTable> tables;

  TableAvailabilityResponse({
    required this.date,
    required this.timeSlot,
    required this.durationMinutes,
    this.isCanteenOpen = true,
    this.openingTime = '09:00',
    this.closingTime = '17:00',
    required this.tables,
  });

  factory TableAvailabilityResponse.fromJson(Map<String, dynamic> json) {
    return TableAvailabilityResponse(
      date: json['date'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
      isCanteenOpen: json['isCanteenOpen'] ?? true,
      openingTime: json['openingTime'] ?? '09:00',
      closingTime: json['closingTime'] ?? '17:00',
      tables: json['tables'] != null
          ? (json['tables'] as List)
              .map((t) => AvailableTable.fromJson(t))
              .toList()
          : [],
    );
  }
}
