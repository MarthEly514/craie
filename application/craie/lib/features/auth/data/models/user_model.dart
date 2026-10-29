enum UserRole { admin, gestionnaire, responsableFiliere }

enum UserStatus { active, suspended }

extension UserRoleJson on UserRole {
  
  String get json => switch (this) {
        UserRole.admin =>'admin',
        UserRole.gestionnaire => 'gestionnaire',
        UserRole.responsableFiliere => 'responsable',
      };

  static UserRole fromJson(String value) => switch (value) {
        'admin' => UserRole.admin,
        'gestionnaire' => UserRole.gestionnaire,
        'responsable' => UserRole.responsableFiliere,
        _ => throw FormatException('Unknown role: $value'),
      };
}

extension UserStatusJson on UserStatus {
  String get json => name; // 'active' | 'suspended'

  static UserStatus fromJson(String value) => switch (value) {
        'active' => UserStatus.active,
        'suspended' => UserStatus.suspended,
        _ => throw FormatException('Unknown status: $value'),
      };
}

class UserModel {
  final String id;
  final String name;

  /// Login identifier: username (admin), email (gestionnaire) or matricule (responsable).
  final String identifier;
  final String password;
  final UserRole role;
  final String? filiere;
  UserStatus status;

  UserModel({
    required this.id,
    required this.name,
    required this.identifier,
    this.password = '',
    required this.role,
    this.filiere,  // only for the responsable role
    this.status = UserStatus.active,
  });

  bool get isSuspended => status == UserStatus.suspended;

  /// Short description shown in the admin lists ("Responsable IM-3").
  String get subtitle => switch (role) {
        UserRole.responsableFiliere => 'Responsable $filiere',
        UserRole.gestionnaire => 'Gestionnaire',
        UserRole.admin => 'Administrateur Systeme',
      };

  /// Role as displayed in the user's own profile.
  String get profileRole => switch (role) {
        UserRole.responsableFiliere => 'Responsable ($filiere)',
        UserRole.gestionnaire => 'Gestionnaire de matériel',
        UserRole.admin => 'Administrateur Systeme',
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['fullName'] as String,
        identifier: json['identifier'] as String,
        role: UserRoleJson.fromJson(json['role'] as String),
        filiere: json['filiere'] as String?,
        status: UserStatusJson.fromJson(json['status'] as String),
      );

  Map<String, dynamic> toJson() => {
        'fullName': name,
        'identifier': identifier,
        'password': password,
        'role': role.json,
        if (filiere != null) 'filiere': filiere,
      };
}
