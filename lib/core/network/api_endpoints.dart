class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://quickplate-backend-z3j0.onrender.com/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Session
  static const String tableSession = '/tables/session';

  // Menu
  static const String studentMenu = '/student/menu';

  // Orders
  static const String studentOrders = '/student/orders';
  static String cancelOrder(String id) => '/student/orders/$id/cancel';
  static String orderDetails(String id) => '/student/orders/$id';

  // Payments
  static const String checkout = '/payments/checkout';
  static const String verifyPayment = '/payments/verify';

  // Notifications
  static const String registerFcmToken = '/auth/notifications/token';
  static const String getNotificationTokens = '/auth/notifications/tokens';
  static const String notifications = '/notifications';
  static String readNotification(String id) => '/notifications/$id/read';
  static const String readAllNotifications = '/notifications/read-all';

  // Cart
  static const String cart = '/student/cart';
  static const String cartAdd = '/student/cart/add';
  static const String cartRemove = '/student/cart/remove';
  static const String cartClear = '/student/cart/clear';
}
