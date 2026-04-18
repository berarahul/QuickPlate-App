class MenuResponse {
  final bool? success;
  final String? message;
  final List<MenuItem>? data;

  MenuResponse({this.success, this.message, this.data});

  factory MenuResponse.fromJson(Map<String, dynamic> json) {
    return MenuResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List).map((i) => MenuItem.fromJson(i)).toList()
          : null,
    );
  }
}

class MenuItem {
  final String? id;
  final String? name;
  final String? description;
  final String? category;
  final int? price;
  final String? imageUrl;
  final bool? isAvailable;
  final int? preparationTimeInMinutes;

  MenuItem({
    this.id,
    this.name,
    this.description,
    this.category,
    this.price,
    this.imageUrl,
    this.isAvailable,
    this.preparationTimeInMinutes,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      price: json['price'] is int ? json['price'] : (json['price'] as num?)?.toInt(),
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'],
      preparationTimeInMinutes: json['preparationTimeInMinutes'],
    );
  }
}
