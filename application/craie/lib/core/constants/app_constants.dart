class AppConstants {
  static const String appName = 'Craie';

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api/v1',);

  // Test admin account (accounts are kept in memory for now).
  static const String adminIdentifier = 'admin1234';
  static const String adminPassword = 'admin1234';

  static const List<String> filieres = [
    'GL-1', 'GL-2', 'GL-3', 'IM-1', 'IM-2', 'IM-3', 'SI-1', 'SI-2', 'SI-3',
  ];

  static const List<String> zones = ['Zone master', 'Zone licence'];
  static const List<String> equipmentTypes = ['Projecteur', 'Rallonge', 'Autre'];
  static const List<String> roomAmenities = ['Climatiseur', 'Electricité'];
}
