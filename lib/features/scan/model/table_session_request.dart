class TableSessionRequest {
  final String tableId;

  TableSessionRequest({required this.tableId});

  Map<String, dynamic> toJson() {
    return {'tableId': tableId};
  }
}
