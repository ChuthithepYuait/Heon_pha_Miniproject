class User {
  final int id;
  final String firstname;
  final String lastname;
  final String email;

  final String role;

  User({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.role = 'customer',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      role: json['role']?.toString() ?? 'customer',
    );
  }

  String get fullName => '$firstname $lastname';

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'role': role,
      };
}