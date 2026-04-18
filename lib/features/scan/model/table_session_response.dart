class TableSessionResponse {
  final bool? success;
  final String? message;
  final SessionData? data;

  TableSessionResponse({this.success, this.message, this.data});

  factory TableSessionResponse.fromJson(Map<String, dynamic> json) {
    return TableSessionResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? SessionData.fromJson(json['data']) : null,
    );
  }
}

class SessionData {
  final TableSession? session;
  final TableInfo? table;

  SessionData({this.session, this.table});

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      session: json['session'] != null
          ? TableSession.fromJson(json['session'])
          : null,
      table: json['table'] != null ? TableInfo.fromJson(json['table']) : null,
    );
  }
}

class TableSession {
  final String? id;
  final String? userId;
  final String? createdAt;
  final String? expiresAt;
  final bool? isActive;
  final String? tableId;
  final String? updatedAt;

  TableSession({
    this.id,
    this.userId,
    this.createdAt,
    this.expiresAt,
    this.isActive,
    this.tableId,
    this.updatedAt,
  });

  factory TableSession.fromJson(Map<String, dynamic> json) {
    return TableSession(
      id: json['_id'],
      userId: json['userId'],
      createdAt: json['createdAt'],
      expiresAt: json['expiresAt'],
      isActive: json['isActive'],
      tableId: json['tableId'],
      updatedAt: json['updatedAt'],
    );
  }
}

class TableInfo {
  final String? id;
  final String? tableId;
  final String? qrCodeUrl;
  final String? qrContent;

  TableInfo({this.id, this.tableId, this.qrCodeUrl, this.qrContent});

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      id: json['_id'],
      tableId: json['tableId'],
      qrCodeUrl: json['qrCodeUrl'],
      qrContent: json['qrContent'],
    );
  }
}
