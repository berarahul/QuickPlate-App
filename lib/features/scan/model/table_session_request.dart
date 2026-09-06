class TableSessionRequest {
  final String tableId;
  final List<String>? chairIds;

  TableSessionRequest({required this.tableId, this.chairIds});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'tableId': tableId};
    if (chairIds != null && chairIds!.isNotEmpty) {
      map['chairIds'] = chairIds;
    }
    return map;
  }
}
