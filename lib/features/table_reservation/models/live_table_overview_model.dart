class LiveChairDetail {
  final String chairId;
  final bool isOccupied;
  final String? userName;

  LiveChairDetail({
    required this.chairId,
    required this.isOccupied,
    this.userName,
  });

  factory LiveChairDetail.fromJson(Map<String, dynamic> json) {
    return LiveChairDetail(
      chairId: json['chairId'] ?? '',
      isOccupied: json['isOccupied'] == true,
      userName: json['userName'],
    );
  }
}

class LiveTableOverviewModel {
  final String id;
  final String tableId;
  final int maxCapacity;
  final int floorNumber;
  final String status; // 'AVAILABLE', 'PARTIALLY_OCCUPIED', 'FULL', 'BLOCKED'
  final List<String> occupiedChairs;
  final int occupiedCount;
  final int availableCount;
  final List<LiveChairDetail> chairDetails;
  final int activeOrderCount;

  LiveTableOverviewModel({
    required this.id,
    required this.tableId,
    required this.maxCapacity,
    required this.floorNumber,
    required this.status,
    required this.occupiedChairs,
    required this.occupiedCount,
    required this.availableCount,
    required this.chairDetails,
    required this.activeOrderCount,
  });

  factory LiveTableOverviewModel.fromJson(Map<String, dynamic> json) {
    final maxCap = json['maxCapacity'] is int ? json['maxCapacity'] as int : 4;
    final floorNum = json['floorNumber'] is int ? json['floorNumber'] as int : 1;
    final occupied = json['occupiedChairs'] != null
        ? List<String>.from(json['occupiedChairs'])
        : <String>[];
    final chairsList = json['chairDetails'] != null
        ? (json['chairDetails'] as List)
            .map((c) => LiveChairDetail.fromJson(c))
            .toList()
        : <LiveChairDetail>[];

    return LiveTableOverviewModel(
      id: json['id'] ?? json['_id'] ?? '',
      tableId: json['tableId'] ?? '',
      maxCapacity: maxCap,
      floorNumber: floorNum,
      status: json['status'] ?? 'AVAILABLE',
      occupiedChairs: occupied,
      occupiedCount: json['occupiedCount'] ?? occupied.length,
      availableCount: json['availableCount'] ?? (maxCap - occupied.length),
      chairDetails: chairsList,
      activeOrderCount: json['activeOrderCount'] ?? 0,
    );
  }
}
