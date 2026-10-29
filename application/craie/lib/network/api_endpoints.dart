class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/me';

  //Users (visible uniquement par l'admin)
  static const String users = '/users';
  static const String generatePassword = '/users/generate-password';
  static String user(String id) =>'/users/$id';


  // Resources (rooms & equipment)
  static const String resources = '/resources';
  static String resource(String id) => '/resources/$id';

  // Reservations
  static const String reservations = '/reservations';
  static String releaseReservation(String id) => '/reservations/$id/release';
}
