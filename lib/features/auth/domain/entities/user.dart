class User {
  final int id;
  final String phone;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String role;
  final String language;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.phone,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.role,
    required this.language,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      phone: json['phone'],
      username: json['username'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'],
      language: json['language'] ?? 'en',
      profilePicture: json['profile_picture'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'full_name': fullName,
    'role': role,
    'language': language,
    'profile_picture': profilePicture,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
